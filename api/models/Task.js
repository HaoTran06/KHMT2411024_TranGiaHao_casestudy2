
const mongoose = require('mongoose');

const taskSchema = new mongoose.Schema({
    // Tiêu đề công việc
    title: {
        type: String,
        required: true,
        trim: true
    },

    // Mô tả
    description: {
        type: String,
        default: ''
    },

    // Ngày bắt đầu
    startDate: {
        type: Date,
        default: null
    },

    // Hạn hoàn thành
    dueDate: {
        type: Date,
        default: null
    },

    // Mức độ ưu tiên
    priority: {
        type: String,
        enum: ['low', 'medium', 'high'],
        default: 'medium'
    },

    // Trạng thái công việc
    status: {
        type: String,
        enum: ['todo', 'in_progress', 'completed'],
        default: 'todo'
    },

    // Người tạo công việc
    createdBy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },

    // Người được giao công việc
    assignees: [{
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User'
    }],

    // Người phụ trách chính
    primaryAssignee: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        default: null
    },

    // Danh sách người được chia sẻ quyền
    sharedWith: [{
        user: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User'
        },
        role: {
            type: String,
            enum: ['viewer', 'editor'],
            default: 'viewer'
        }
    }]

}, {
    timestamps: true
});

module.exports = mongoose.model('Task', taskSchema);
