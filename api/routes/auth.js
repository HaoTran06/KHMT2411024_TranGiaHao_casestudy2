
const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/User');

const router = express.Router();

// API đăng ký
router.post('/register', async (req, res) => {
    try {
        const { name, email, password } = req.body;

        // Kiểm tra dữ liệu
        if (!name || !email || !password) {
            return res.status(400).json({
                message: 'Vui lòng nhập đầy đủ thông tin!'
            });
        }

        // Kiểm tra email đã tồn tại
        const existingUser = await User.findOne({ email });

        if (existingUser) {
            return res.status(400).json({
                message: 'Email đã được đăng ký!'
            });
        }

        // Mã hóa mật khẩu
        const hashedPassword = await bcrypt.hash(password, 10);

        // Tạo tài khoản
        const newUser = new User({
            name,
            email,
            password: hashedPassword
        });

        await newUser.save();

        // Tạo JWT
        const token = jwt.sign(
            { id: newUser._id },
            process.env.JWT_SECRET,
            { expiresIn: '7d' }
        );

        res.status(201).json({
            message: 'Đăng ký thành công!',
            token,
            user: {
                id: newUser._id,
                name: newUser.name,
                email: newUser.email
            }
        });

    } catch (error) {
        res.status(500).json({
            message: 'Lỗi server!',
            error: error.message
        });
    }
});

// API đăng nhập
router.post('/login', async (req, res) => {
    try {
        const { email, password } = req.body;

        // Kiểm tra dữ liệu
        if (!email || !password) {
            return res.status(400).json({
                message: 'Vui lòng nhập email và mật khẩu!'
            });
        }

        // Tìm tài khoản
        const user = await User.findOne({
            email: email.trim().toLowerCase()
        });

        if (!user) {
            return res.status(401).json({
                message: 'Email hoặc mật khẩu không chính xác!'
            });
        }

        // Kiểm tra mật khẩu
        const isMatch = await bcrypt.compare(
            password,
            user.password
        );

        if (!isMatch) {
            return res.status(401).json({
                message: 'Email hoặc mật khẩu không chính xác!'
            });
        }

        // Tạo JWT
        const token = jwt.sign(
            { id: user._id },
            process.env.JWT_SECRET,
            { expiresIn: '7d' }
        );

        res.status(200).json({
            message: 'Đăng nhập thành công!',
            token,
            user: {
                id: user._id,
                name: user.name,
                email: user.email
            }
        });

    } catch (error) {
        res.status(500).json({
            message: 'Lỗi server!',
            error: error.message
        });
    }
});


module.exports = router;
