
const express = require('express');
const cors = require('cors');
const mongoose = require('mongoose');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Import routes
const authRoutes = require('./routes/auth');
const taskRoutes = require('./routes/task');
const notificationRoutes = require('./routes/notification');
const profileRoutes = require('./routes/profile');

// Middleware
app.use(cors());
app.use(express.json());

// API routes
app.use('/api/auth', authRoutes);
app.use('/api/tasks', taskRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/profile', profileRoutes);

// API kiểm tra trạng thái server
app.get('/', (req, res) => {
    res.json({
        message: 'TaskManager API is running!'
    });
});

// Kết nối MongoDB và khởi động server
const startServer = async () => {
    try {
        if (!process.env.MONGO_URI) {
            throw new Error('MONGO_URI chưa được cấu hình trong file .env');
        }

        await mongoose.connect(process.env.MONGO_URI);

        console.log('MongoDB connected successfully!');

        app.listen(PORT, '0.0.0.0', () => {
            console.log(`Server is running on port ${PORT}`);
        });

    } catch (err) {
        console.error('MongoDB connection error:', err.message);
        process.exit(1);
    }
};

startServer();
