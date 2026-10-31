
const mongoose = require('mongoose');
require('dotenv').config();

const User = require('./models/User');
const Task = require('./models/Task');

async function seedTasks() {
  try {
    await mongoose.connect(process.env.MONGO_URI);

    const user = await User.findOne({ email: 'hao@gmail.com' });

    if (!user) {
      console.log('Không tìm thấy tài khoản hao@gmail.com');
      return;
    }

    await Task.insertMany([
      {
        title: 'Hoàn thành bài tập Flutter',
        description: 'Xây dựng giao diện ứng dụng TaskManager',
        status: 'in_progress',
        createdBy: user._id,
      },
      {
        title: 'Ôn tập cơ sở dữ liệu',
        description: 'Ôn MongoDB và truy vấn dữ liệu',
        status: 'todo',
        createdBy: user._id,
      },
      {
        title: 'Hoàn thiện báo cáo',
        description: 'Chuẩn bị nội dung báo cáo dự án',
        status: 'completed',
        createdBy: user._id,
      },
    ]);

    console.log('Đã tạo 3 công việc mẫu!');
  } catch (error) {
    console.error(error);
  } finally {
    await mongoose.disconnect();
  }
}

seedTasks();
