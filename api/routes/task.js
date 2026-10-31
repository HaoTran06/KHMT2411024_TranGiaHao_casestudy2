
const express = require('express');
const mongoose = require('mongoose');
const router = express.Router();

const Task = require('../models/Task');
const User = require('../models/User');
const authMiddleware = require('../middleware/authMiddleware');

const isValidId = (id) => mongoose.Types.ObjectId.isValid(id);

// Xác định quyền bằng truy vấn MongoDB
const getTaskPermission = async (taskId, userId) => {
    const id = new mongoose.Types.ObjectId(userId);

    const task = await Task.findById(taskId).lean();

    if (!task) return null;

    if (task.createdBy.toString() === userId.toString()) {
        return 'owner';
    }

    if (task.assignees.some(item => item.toString() === userId.toString())) {
        return 'editor';
    }

    const shared = task.sharedWith.find(
        item => item.user.toString() === userId.toString()
    );

    return shared ? shared.role : null;
};

// Kiểm tra danh sách user
const validateUsers = async (userIds) => {
    if (!Array.isArray(userIds)) return false;

    if (userIds.some(id => !isValidId(id))) return false;

    const uniqueIds = [...new Set(userIds.map(String))];

    const users = await User.find({
        _id: { $in: uniqueIds }
    }).select('_id');

    return users.length === uniqueIds.length;
};

// Lấy danh sách task
router.get('/', authMiddleware, async (req, res) => {
    try {
        const tasks = await Task.find({
            $or: [
                { createdBy: req.user.id },
                { assignees: req.user.id },
                { 'sharedWith.user': req.user.id }
            ]
        })
            .populate('createdBy', 'name email')
            .populate('assignees', 'name email')
            .populate('primaryAssignee', 'name email')
            .populate('sharedWith.user', 'name email')
            .sort({ createdAt: -1 });

        res.status(200).json({
            message: 'Lấy danh sách thành công!',
            tasks
        });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// Xem chi tiết task
router.get('/:id', authMiddleware, async (req, res) => {
    try {
        if (!isValidId(req.params.id)) {
            return res.status(400).json({
                message: 'ID task không hợp lệ'
            });
        }

        const task = await Task.findById(req.params.id).lean();

        if (!task) {
            return res.status(404).json({
                message: 'Không tìm thấy task'
            });
        }

        const permission = await getTaskPermission(
            req.params.id,
            req.user.id
        );

        if (!permission) {
            console.log('ACCESS DEBUG:', {
                userId: req.user.id,
                createdBy: task.createdBy,
                assignees: task.assignees,
                sharedWith: task.sharedWith
            });

            return res.status(403).json({
                message: 'Bạn không có quyền xem công việc này'
            });
        }

        const populatedTask = await Task.findById(req.params.id)
            .populate('createdBy', 'name email')
            .populate('assignees', 'name email')
            .populate('primaryAssignee', 'name email')
            .populate('sharedWith.user', 'name email');

        res.status(200).json({
            message: 'Lấy chi tiết thành công!',
            permission,
            task: populatedTask
        });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// Tạo task
router.post('/', authMiddleware, async (req, res) => {
    try {
        const {
            title,
            description,
            status,
            assignees = [],
            primaryAssignee
        } = req.body;

        if (typeof title !== 'string' || !title.trim()) {
            return res.status(400).json({
                message: 'Vui lòng nhập tiêu đề'
            });
        }

        if (!await validateUsers(assignees)) {
            return res.status(400).json({
                message: 'Danh sách người được giao không hợp lệ'
            });
        }

        if (primaryAssignee &&
            !assignees.map(String).includes(String(primaryAssignee))) {
            return res.status(400).json({
                message: 'Người phụ trách chính phải nằm trong danh sách được giao'
            });
        }

        const task = await Task.create({
            title: title.trim(),
            description,
            status,
            createdBy: req.user.id,
            assignees,
            primaryAssignee: primaryAssignee || null
        });

        res.status(201).json({
            message: 'Tạo task thành công!',
            task
        });
    } catch (error) {
        res.status(400).json({ message: error.message });
    }
});

// Giao việc cho nhiều người
router.put('/:id/assign', authMiddleware, async (req, res) => {
    try {
        const { assignees, primaryAssignee } = req.body;

        const task = await Task.findById(req.params.id);

        if (!task) {
            return res.status(404).json({
                message: 'Không tìm thấy task'
            });
        }

        if (task.createdBy.toString() !== req.user.id.toString()) {
            return res.status(403).json({
                message: 'Chỉ chủ task mới được giao việc'
            });
        }

        if (!Array.isArray(assignees) || !await validateUsers(assignees)) {
            return res.status(400).json({
                message: 'Danh sách người được giao không hợp lệ'
            });
        }

        if (primaryAssignee &&
            !assignees.map(String).includes(String(primaryAssignee))) {
            return res.status(400).json({
                message: 'Người phụ trách chính phải nằm trong danh sách được giao'
            });
        }

        task.assignees = assignees;
        task.primaryAssignee = primaryAssignee || null;

        await task.save();

        res.status(200).json({
            message: 'Giao việc thành công!',
            task
        });
    } catch (error) {
        res.status(400).json({ message: error.message });
    }
});

// Chia sẻ task
router.post('/:id/share', authMiddleware, async (req, res) => {
    try {
        const { userId, role } = req.body;

        if (!isValidId(userId)) {
            return res.status(400).json({
                message: 'User ID không hợp lệ'
            });
        }

        if (!['viewer', 'editor'].includes(role)) {
            return res.status(400).json({
                message: 'Quyền phải là viewer hoặc editor'
            });
        }

        const task = await Task.findById(req.params.id);

        if (!task) {
            return res.status(404).json({
                message: 'Không tìm thấy task'
            });
        }

        if (task.createdBy.toString() !== req.user.id.toString()) {
            return res.status(403).json({
                message: 'Chỉ chủ task mới được chia sẻ'
            });
        }

        if (userId.toString() === req.user.id.toString()) {
            return res.status(400).json({
                message: 'Không thể chia sẻ cho chính mình'
            });
        }

        const userExists = await User.findById(userId);

        if (!userExists) {
            return res.status(404).json({
                message: 'Không tìm thấy người dùng'
            });
        }

        const existing = task.sharedWith.find(
            item => item.user.toString() === userId.toString()
        );

        if (existing) {
            existing.role = role;
        } else {
            task.sharedWith.push({ user: userId, role });
        }

        await task.save();

        res.status(200).json({
            message: 'Chia sẻ task thành công!',
            task
        });
    } catch (error) {
        res.status(400).json({ message: error.message });
    }
});

// Cập nhật task: owner hoặc editor
router.put('/:id', authMiddleware, async (req, res) => {
    try {
        const task = await Task.findById(req.params.id);

        if (!task) {
            return res.status(404).json({
                message: 'Không tìm thấy task'
            });
        }

        const permission = await getTaskPermission(
            req.params.id,
            req.user.id
        );

        if (!['owner', 'editor'].includes(permission)) {
            return res.status(403).json({
                message: 'Bạn không có quyền sửa task'
            });
        }

        const { title, description, status } = req.body;

        if (title !== undefined) {
            if (typeof title !== 'string' || !title.trim()) {
                return res.status(400).json({
                    message: 'Tiêu đề không được để trống'
                });
            }
            task.title = title.trim();
        }

        if (description !== undefined) task.description = description;
        if (status !== undefined) task.status = status;

        await task.save();

        res.status(200).json({
            message: 'Cập nhật task thành công!',
            task
        });
    } catch (error) {
        res.status(400).json({ message: error.message });
    }
});

// Xóa task: chỉ owner
router.delete('/:id', authMiddleware, async (req, res) => {
    try {
        const task = await Task.findById(req.params.id);

        if (!task) {
            return res.status(404).json({
                message: 'Không tìm thấy task'
            });
        }

        if (task.createdBy.toString() !== req.user.id.toString()) {
            return res.status(403).json({
                message: 'Chỉ chủ task mới được xóa'
            });
        }

        await task.deleteOne();

        res.status(200).json({
            message: 'Xóa task thành công!'
        });
    } catch (error) {
        res.status(400).json({ message: error.message });
    }
});

module.exports = router;
