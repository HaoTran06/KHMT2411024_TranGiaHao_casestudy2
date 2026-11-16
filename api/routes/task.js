
const express = require('express');
const mongoose = require('mongoose');
const router = express.Router();

const Task = require('../models/Task');
const User = require('../models/User');
const Notification = require('../models/Notification');
const authMiddleware = require('../middleware/authMiddleware');

const isValidId = (id) => mongoose.Types.ObjectId.isValid(id);

const validStatuses = ['todo', 'in_progress', 'completed'];
const validPriorities = ['low', 'medium', 'high'];

// Kiểm tra ngày hợp lệ
const parseDate = (value) => {
    if (value === null || value === '') return null;

    const date = new Date(value);

    if (Number.isNaN(date.getTime())) return undefined;

    return date;
};

// Xác định quyền của người dùng
const getTaskPermission = async (taskId, userId) => {
    const task = await Task.findById(taskId).lean();

    if (!task) return null;

    if (task.createdBy.toString() === userId.toString()) {
        return 'owner';
    }

    if (task.assignees.some(
        item => item.toString() === userId.toString()
    )) {
        return 'editor';
    }

    const shared = task.sharedWith.find(
        item => item.user.toString() === userId.toString()
    );

    return shared ? shared.role : null;
};

// Kiểm tra danh sách người dùng
const validateUsers = async (userIds) => {
    if (!Array.isArray(userIds)) return false;

    if (userIds.some(id => !isValidId(id))) return false;

    const uniqueIds = [...new Set(userIds.map(String))];

    const users = await User.find({
        _id: { $in: uniqueIds }
    }).select('_id');

    return users.length === uniqueIds.length;
};

// Populate thông tin task
const populateTask = (query) => {
    return query
        .populate('createdBy', 'name email')
        .populate('assignees', 'name email')
        .populate('primaryAssignee', 'name email')
        .populate('sharedWith.user', 'name email');
};

// Tìm kiếm người dùng để giao việc
router.get('/users/search', authMiddleware, async (req, res) => {
    try {
        const keyword = (req.query.q || '').trim();

        if (!keyword) {
            return res.status(200).json({ users: [] });
        }

        const users = await User.find({
            _id: { $ne: req.user.id },
            $or: [
                { name: { $regex: keyword, $options: 'i' } },
                { email: { $regex: keyword, $options: 'i' } }
            ]
        })
            .select('name email')
            .limit(20);

        res.status(200).json({ users });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// Lấy danh sách task
router.get('/', authMiddleware, async (req, res) => {
    try {
        const { category, search, status, priority, sort } = req.query;

        const filter = {
            $or: [
                { createdBy: req.user.id },
                { assignees: req.user.id },
                { 'sharedWith.user': req.user.id }
            ]
        };

        if (category === 'created') {
            filter.$or = [{ createdBy: req.user.id }];
        } else if (category === 'assigned') {
            filter.$or = [{ assignees: req.user.id }];
        } else if (category === 'shared') {
            filter.$or = [{ 'sharedWith.user': req.user.id }];
        }

        if (search) {
            filter.title = { $regex: search, $options: 'i' };
        }

        if (status && validStatuses.includes(status)) {
            filter.status = status;
        }

        if (priority && validPriorities.includes(priority)) {
            filter.priority = priority;
        }

        let sortOption = { createdAt: -1 };

        if (sort === 'oldest') sortOption = { createdAt: 1 };
        if (sort === 'dueDate') sortOption = { dueDate: 1 };
        if (sort === 'priority') {
            sortOption = { priority: -1, createdAt: -1 };
        }

        const tasks = await populateTask(
            Task.find(filter).sort(sortOption)
        );

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

        const permission = await getTaskPermission(
            req.params.id,
            req.user.id
        );

        if (!permission) {
            return res.status(403).json({
                message: 'Bạn không có quyền xem công việc này'
            });
        }

        const task = await populateTask(
            Task.findById(req.params.id)
        );

        if (!task) {
            return res.status(404).json({
                message: 'Không tìm thấy task'
            });
        }

        res.status(200).json({
            message: 'Lấy chi tiết thành công!',
            permission,
            task
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
            startDate,
            dueDate,
            priority = 'medium',
            status = 'todo',
            assignees = [],
            primaryAssignee
        } = req.body;

        if (typeof title !== 'string' || !title.trim()) {
            return res.status(400).json({
                message: 'Vui lòng nhập tiêu đề'
            });
        }

        if (!validStatuses.includes(status)) {
            return res.status(400).json({
                message: 'Trạng thái không hợp lệ'
            });
        }

        if (!validPriorities.includes(priority)) {
            return res.status(400).json({
                message: 'Độ ưu tiên không hợp lệ'
            });
        }

        const parsedStartDate = parseDate(startDate);
        const parsedDueDate = parseDate(dueDate);

        if (parsedStartDate === undefined || parsedDueDate === undefined) {
            return res.status(400).json({
                message: 'Ngày bắt đầu hoặc hạn hoàn thành không hợp lệ'
            });
        }

        if (parsedStartDate && parsedDueDate &&
            parsedStartDate > parsedDueDate) {
            return res.status(400).json({
                message: 'Ngày bắt đầu không được sau hạn hoàn thành'
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
            description: description || '',
            startDate: parsedStartDate,
            dueDate: parsedDueDate,
            priority,
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
        if (!isValidId(req.params.id)) {
            return res.status(400).json({
                message: 'ID task không hợp lệ'
            });
        }

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

        if (!Array.isArray(assignees) ||
            !await validateUsers(assignees)) {
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

        const oldAssignees = task.assignees.map(
            id => id.toString()
        );

        task.assignees = [...new Set(assignees.map(String))];
        task.primaryAssignee = primaryAssignee || null;

        await task.save();

        const newAssignees = task.assignees
            .map(id => id.toString())
            .filter(id =>
                !oldAssignees.includes(id) &&
                id !== req.user.id.toString()
            );

        if (newAssignees.length > 0) {
            await Notification.insertMany(
                newAssignees.map(userId => ({
                    recipient: userId,
                    sender: req.user.id,
                    task: task._id,
                    type: 'assigned',
                    message: `Bạn được giao công việc: ${task.title}`
                }))
            );
        }

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
        if (!isValidId(req.params.id)) {
            return res.status(400).json({
                message: 'ID task không hợp lệ'
            });
        }

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

        const shouldNotify = !existing || existing.role !== role;

        if (existing) {
            existing.role = role;
        } else {
            task.sharedWith.push({ user: userId, role });
        }

        await task.save();

        if (shouldNotify) {
            await Notification.create({
                recipient: userId,
                sender: req.user.id,
                task: task._id,
                type: 'shared',
                message: `Bạn được chia sẻ công việc: ${task.title} với quyền ${role}`
            });
        }

        res.status(200).json({
            message: 'Chia sẻ task thành công!',
            task
        });
    } catch (error) {
        res.status(400).json({ message: error.message });
    }
});

// Thu hồi quyền chia sẻ
router.delete('/:id/share/:userId', authMiddleware, async (req, res) => {
    try {
        const { id, userId } = req.params;

        if (!isValidId(id) || !isValidId(userId)) {
            return res.status(400).json({
                message: 'ID không hợp lệ'
            });
        }

        const task = await Task.findById(id);

        if (!task) {
            return res.status(404).json({
                message: 'Không tìm thấy task'
            });
        }

        if (task.createdBy.toString() !== req.user.id.toString()) {
            return res.status(403).json({
                message: 'Chỉ chủ task mới được thu hồi quyền chia sẻ'
            });
        }

        const oldLength = task.sharedWith.length;

        task.sharedWith = task.sharedWith.filter(
            item => item.user.toString() !== userId
        );

        if (task.sharedWith.length === oldLength) {
            return res.status(404).json({
                message: 'Người dùng chưa được chia sẻ task'
            });
        }

        await task.save();

        res.status(200).json({
            message: 'Thu hồi quyền chia sẻ thành công!',
            task
        });
    } catch (error) {
        res.status(400).json({ message: error.message });
    }
});

// Cập nhật task
router.put('/:id', authMiddleware, async (req, res) => {
    try {
        if (!isValidId(req.params.id)) {
            return res.status(400).json({
                message: 'ID task không hợp lệ'
            });
        }

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

        const {
            title,
            description,
            startDate,
            dueDate,
            priority,
            status
        } = req.body;

        if (title !== undefined) {
            if (typeof title !== 'string' || !title.trim()) {
                return res.status(400).json({
                    message: 'Tiêu đề không được để trống'
                });
            }

            task.title = title.trim();
        }

        if (description !== undefined) {
            task.description = description;
        }

        if (status !== undefined) {
            if (!validStatuses.includes(status)) {
                return res.status(400).json({
                    message: 'Trạng thái không hợp lệ'
                });
            }

            task.status = status;
        }

        if (priority !== undefined) {
            if (!validPriorities.includes(priority)) {
                return res.status(400).json({
                    message: 'Độ ưu tiên không hợp lệ'
                });
            }

            task.priority = priority;
        }

        if (startDate !== undefined) {
            const parsed = parseDate(startDate);

            if (parsed === undefined) {
                return res.status(400).json({
                    message: 'Ngày bắt đầu không hợp lệ'
                });
            }

            task.startDate = parsed;
        }

        if (dueDate !== undefined) {
            const parsed = parseDate(dueDate);

            if (parsed === undefined) {
                return res.status(400).json({
                    message: 'Hạn hoàn thành không hợp lệ'
                });
            }

            task.dueDate = parsed;
        }

        if (task.startDate && task.dueDate &&
            task.startDate > task.dueDate) {
            return res.status(400).json({
                message: 'Ngày bắt đầu không được sau hạn hoàn thành'
            });
        }

        await task.save();

        res.status(200).json({
            message: 'Cập nhật task thành công!',
            task
        });
    } catch (error) {
        res.status(400).json({ message: error.message });
    }
});

// Xóa task
router.delete('/:id', authMiddleware, async (req, res) => {
    try {
        if (!isValidId(req.params.id)) {
            return res.status(400).json({
                message: 'ID task không hợp lệ'
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
