const bcrypt = require('bcrypt');

async function run() {
  const password = "Admin@123";
  const saltRounds = 10;

  const hashed = await bcrypt.hash(password, saltRounds);
  console.log("✅ Mã băm của mật khẩu:", hashed);
}

run();
