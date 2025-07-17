const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const bcrypt = require('bcrypt');

const app = express();
const PORT = 3000;
const saltRounds = 10;

// Middleware
app.use(cors());
app.use(express.json());

// Kết nối MongoDB
mongoose.connect('mongodb://127.0.0.1:27017/sonxemaycantho')
  .then(() => console.log('✅ Đã kết nối MongoDB'))
  .catch(err => console.error('❌ Lỗi kết nối MongoDB:', err));

// Schema + Model
const AccountSchema = new mongoose.Schema({
  name: { type: String, required: true },
  phoneNumber: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  role: { type: String, enum: ['manager', 'staff', 'customer'], default: 'customer' },
  isActive: { type: Boolean, default: true }
});

const Account = mongoose.model('Account', AccountSchema);

// API đăng ký
app.post('/api/register', async (req, res) => {
  try {
    const { name, phoneNumber, password, role } = req.body;

    if (!name || !phoneNumber || !password) {
      return res.status(400).json({ message: 'Thiếu thông tin!' });
    }

    const exists = await Account.findOne({ phoneNumber });
    if (exists) {
      return res.status(400).json({ message: 'Số điện thoại đã tồn tại!' });
    }

    const hashedPassword = await bcrypt.hash(password, saltRounds);

    const newAccount = new Account({
      name,
      phoneNumber,
      password: hashedPassword,
      role: role || 'customer',
    });

    await newAccount.save();

    res.status(201).json({
      message: 'Đăng ký thành công!',
      account: {
        name: newAccount.name,
        phoneNumber: newAccount.phoneNumber,
        role: newAccount.role,
      }
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Lỗi server.' });
  }
});

// API đăng nhập
app.post('/api/login', async (req, res) => {
  try {
    const { phoneNumber, password } = req.body;

    if (!phoneNumber || !password) {
      return res.status(400).json({ message: 'Thiếu thông tin đăng nhập.' });
    }

    const account = await Account.findOne({ phoneNumber });
    if (!account) {
      return res.status(404).json({ message: 'Không tìm thấy tài khoản.' });
    }

    const match = await bcrypt.compare(password, account.password);
    if (!match) {
      return res.status(401).json({ message: 'Sai mật khẩu.' });
    }

    res.json({
      role: account.role,
      name: account.name,
      phoneNumber: account.phoneNumber
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Lỗi server.' });
  }
});

// Khởi chạy server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Server đang chạy tại http://localhost:${PORT}`);
});
