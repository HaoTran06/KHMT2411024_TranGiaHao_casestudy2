
const express = require('express');
const router = express.Router();

const Task = require('../models/Task');

// Lấy danh sách công việc
router.get('/', async (req, res) => {
  try {
    const tasks = await Task.find()
      .populate('createdBy', 'name email')
      .sort({ createdAt: -1 });

    res.status(200).json({
      message: 'Lấy danh sách công việc thành công!',
      tasks,
    });
  } catch (error) {
    res.status(500).json({
      message: 'Lỗi máy chủ',
      error: error.message,
    });
  }
});

// Lấy chi tiết một công việc
router.get('/:id', async (req, res) => {
  try {
    const task = await Task.findById(req.params.id)
      .populate('createdBy', 'name email');

    if (!task) {
      return res.status(404).json({
        message: 'Không tìm thấy công việc',
      });
    }

    res.status(200).json({
      message: 'Lấy chi tiết công việc thành công!',
      task,
    });
  } catch (error) {
    res.status(500).json({
      message: 'Lỗi máy chủ',
      error: error.message,
    });
  }
});

module.exports = router;
