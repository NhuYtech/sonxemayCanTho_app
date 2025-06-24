const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');

const app = express();
const PORT = 3000;

// Middleware cho phép gọi từ ứng dụng Flutter
app.use(cors());
app.use(express.json());

// Kết nối MongoDB local
mongoose.connect('mongodb://localhost:27017/sonxemaycantho', {
  useNewUrlParser: true,
  useUnifiedTopology: true,
}).then(() => console.log('✅ Đã kết nối MongoDB'))
  .catch(err => console.error('❌ Lỗi kết nối MongoDB:', err));

// Định nghĩa schema đơn giản
const Item = mongoose.model('Item', {
  name: String,
  quantity: Number,
});

// API: Lấy danh sách item
app.get('/items', async (req, res) => {
  const items = await Item.find();
  res.json(items);
});

// API: Thêm item mới
app.post('/items', async (req, res) => {
  const { name, quantity } = req.body;
  const newItem = new Item({ name, quantity });
  await newItem.save();
  res.status(201).json(newItem);
});

// Khởi chạy server
app.listen(PORT, () => {
  console.log(`🚀 Server đang chạy tại http://localhost:${PORT}`);
});
