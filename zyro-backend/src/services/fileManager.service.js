const fs = require('fs');
const path = require('path');
const os = require('os');
const ffmpeg = require('fluent-ffmpeg');

function getTempDir() {
  return path.join(os.tmpdir(), 'zyro-temp');
}

function getDownloadsDir() {
  return path.join(os.tmpdir(), 'zyro-downloads');
}

function ensureDirectoriesExist() {
  const dirs = [
    getTempDir(),
    getDownloadsDir()
  ];
  dirs.forEach(d => {
    if (!fs.existsSync(d)) {
      fs.mkdirSync(d, { recursive: true });
    }
  });
}

function deleteFile(filePath) {
  if (filePath && fs.existsSync(filePath)) {
    try {
      fs.unlinkSync(filePath);
      console.log(`Deleted file: ${filePath}`);
    } catch (e) {
      console.error(`Error deleting file ${filePath}:`, e);
    }
  }
}

function verifyVideoHeight(filePath, expectedHeight) {
  return new Promise((resolve, reject) => {
    if (!expectedHeight) {
      return resolve(true);
    }

    console.log(`Verifying video height for ${filePath}. Expected: ~${expectedHeight}p`);
    
    ffmpeg.ffprobe(filePath, (err, metadata) => {
      if (err) {
        return reject(new Error('ffprobe verification failed: ' + err.message));
      }

      const videoStream = metadata.streams.find(s => s.codec_type === 'video');
      if (!videoStream) {
        return reject(new Error('ffprobe verification failed: No video stream found in output file'));
      }

      const actualHeight = videoStream.height;
      console.log(`ffprobe verified video height: ${actualHeight}px`);

      const diff = Math.abs(actualHeight - expectedHeight);
      if (diff > 20) {
        return reject(new Error(`Validation failed: Expected height around ${expectedHeight}px, but got ${actualHeight}px`));
      }

      resolve(true);
    });
  });
}

module.exports = {
  ensureDirectoriesExist,
  deleteFile,
  verifyVideoHeight,
  getTempDir,
  getDownloadsDir
};
