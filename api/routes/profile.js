
const express = require('express');
const router = express.Router();

const User = require('../models/User');
const Task = require('../models/Task');
const authMiddleware = require('../middleware/authMiddleware');

// GET /api/profile
router.get('/', authMiddleware, async (req, res) => {
    try {
        const userId = req.user.id;

        // Lấy thông tin cá nhân
        const user = await User.findById(userId)
            .select('-password');

        if (!user) {
            return res.status(404).json({
                message: 'Không tìm thấy người dùng!'
            });
        }

        // Lấy tất cả công việc liên quan đến người dùng
        const tasks = await Task.find({
            $or: [
                { createdBy: userId },
                { assignees: userId },
                { 'sharedWith.user': userId }
            ]
        });

        // Thống kê theo từng nhóm
        const ownedTasks = tasks.filter(
            task => task.createdBy.toString() === userId
        );

        const assignedTasks = tasks.filter(
            task => task.assignees.some(
                id => id.toString() === userId
            )
        );

        const sharedTasks = tasks.filter(
            task => task.sharedWith.some(
                item => item.user.toString() === userId
            )
        );

        // Thống kê trạng thái, không đếm trùng
        const statistics = {
            total: tasks.length,
            todo: tasks.filter(
                task => task.status === 'todo'
            ).length,
            inProgress: tasks.filter(
                task => task.status === 'in_progress'
            ).length,
            completed: tasks.filter(
                task => task.status === 'completed'
            ).length,
            owned: ownedTasks.length,
            assigned: assignedTasks.length,
            shared: sharedTasks.length
        };

        res.status(200).json({
            message: 'Lấy hồ sơ thành công!',
            user,
            statistics
        });

    } catch (error) {
        res.status(500).json({
            message: 'Lỗi server!',
            error: error.message
        });
    }
});

module.exports = router;
