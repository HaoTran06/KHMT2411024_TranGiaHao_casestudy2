const express = require('express');
const router = express.Router();

const Notification = require('../models/Notification');
const authMiddleware = require('../middleware/authMiddleware');

// Lấy danh sách thông báo của người dùng hiện tại
router.get('/', authMiddleware, async (req, res) => {
    try {
        const notifications = await Notification.find({
            recipient: req.user.id
        })
            .populate('sender', 'name email')
            .populate('task', 'title')
            .sort({ createdAt: -1 });

        res.json(notifications);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// Đánh dấu thông báo đã đọc
router.put('/:id/read', authMiddleware, async (req, res) => {
    try {
        const notification = await Notification.findOneAndUpdate(
            {
                _id: req.params.id,
                recipient: req.user.id
            },
            { isRead: true },
            { new: true }
        );

        if (!notification) {
            return res.status(404).json({
                message: 'Không tìm thấy thông báo!'
            });
        }

        res.json({
            message: 'Đã đánh dấu đã đọc!',
            notification
        });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

module.exports = router;