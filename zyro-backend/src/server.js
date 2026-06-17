const express = require('express');
const cors = require('cors');
const path = require('path');
const downloadRoutes = require('./routes/download.routes');
const errorHandler = require('./middleware/errorHandler');
const fileManager = require('./services/fileManager.service');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

// Serve downloads statically
app.use('/downloads', express.static(fileManager.getDownloadsDir()));

// Mount routes
app.use('/api/video', downloadRoutes);

app.get('/', (req, res) => {
  res.json({ success: true, message: 'Zyro Downloader Backend is active' });
});

// Global error handler
app.use(errorHandler);

app.listen(PORT, () => {
  console.log(`Zyro Downloader Backend running on port ${PORT}`);
  fileManager.ensureDirectoriesExist();
});
