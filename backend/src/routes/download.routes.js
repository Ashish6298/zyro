const express = require('express');
const router = express.Router();
const controller = require('../controllers/download.controller');

router.post('/metadata', controller.getVideoMetadata);
router.post('/download', controller.startDownloadTask);
router.get('/status/:taskId', controller.getTaskStatus);

module.exports = router;
