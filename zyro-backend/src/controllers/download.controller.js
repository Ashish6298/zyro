const { v4: uuidv4 } = require('uuid');
const path = require('path');
const fs = require('fs');
const extractorService = require('../services/videoExtractor.service');
const formatSelector = require('../services/formatSelector.service');
const downloadManager = require('../services/downloadManager.service');
const mergeService = require('../services/merge.service');
const fileManager = require('../services/fileManager.service');
const { sanitizeSingleVideoUrl } = require('../services/urlSanitizer.service');

const tasks = {};

function rejectPlaylistDownloads(url) {
  if (!url) return false;
  try {
    const parsed = new URL(url);
    const hostname = parsed.hostname.toLowerCase();
    
    // Check if it's a YouTube playlist page without a specific video
    if (hostname.includes('youtube.com') || hostname.includes('youtu.be')) {
      if (parsed.pathname.startsWith('/playlist') || (parsed.searchParams.has('list') && !parsed.searchParams.has('v'))) {
        return true;
      }
    }
    return false;
  } catch {
    return false;
  }
}

async function getVideoMetadata(req, res, next) {
  try {
    let { url } = req.body;
    if (!url) {
      return res.status(400).json({ success: false, error: 'URL is required' });
    }

    if (rejectPlaylistDownloads(url)) {
      return res.status(400).json({ success: false, error: 'Playlist downloads are not supported.' });
    }

    url = sanitizeSingleVideoUrl(url);

    const metadata = await extractorService.extractMetadata(url);
    res.json({ success: true, ...metadata });
  } catch (error) {
    next(error);
  }
}

function startDownloadTask(req, res, next) {
  try {
    let { url, canonicalVideoUrl, formatId, expectedHeight, mode } = req.body;
    
    // Respect canonicalVideoUrl if provided
    let targetUrl = canonicalVideoUrl || url;

    if (!targetUrl || !formatId) {
      return res.status(400).json({ success: false, error: 'URL and formatId are required' });
    }

    if (rejectPlaylistDownloads(targetUrl)) {
      return res.status(400).json({ success: false, error: 'Playlist downloads are not supported.' });
    }

    targetUrl = sanitizeSingleVideoUrl(targetUrl);

    const taskId = uuidv4();
    tasks[taskId] = {
      id: taskId,
      state: 'extracting',
      progress: 0,
      url: targetUrl,
      formatId,
      expectedHeight: expectedHeight ? parseInt(expectedHeight, 10) : null,
      mode: mode || 'video',
      filename: '',
      downloadUrl: null,
      error: null
    };

    processDownloadInBackground(taskId);

    res.json({ success: true, taskId });
  } catch (error) {
    next(error);
  }
}

async function processDownloadInBackground(taskId) {
  const task = tasks[taskId];
  let tempVideoPath = null;
  let tempAudioPath = null;
  let finalPath = null;

  try {
    fileManager.ensureDirectoriesExist();

    const metadata = await extractorService.extractMetadata(task.url);
    
    const requestedFormat = metadata.formats.find(f => f.formatId === task.formatId);
    if (!requestedFormat) {
      throw new Error(`Requested format ${task.formatId} not found.`);
    }

    if (task.expectedHeight && requestedFormat.height) {
      const diff = Math.abs(requestedFormat.height - task.expectedHeight);
      if (diff > 20) {
        throw new Error(`Format ID ${task.formatId} height (${requestedFormat.height}p) does not match requested quality ${task.expectedHeight}p.`);
      }
    }

    const selected = formatSelector.selectFormats(metadata.formats, task.formatId, task.mode);

    const cleanTitle = metadata.title.replace(/[^\w\s.-]/g, '_').trim();
    let ext = task.mode === 'audio' ? '.mp3' : (selected.videoFormat?.ext || requestedFormat.ext || '.mp4');
    const finalExt = ext.startsWith('.') ? ext : `.${ext}`;
    const displayHeight = task.mode === 'audio' ? 'audio' : `${requestedFormat.height || 'unknown'}p`;
    task.filename = `${cleanTitle}-${displayHeight}${finalExt}`;

    const tempDir = fileManager.getTempDir();
    const downloadsDir = fileManager.getDownloadsDir();

    if (task.mode === 'audio') {
      let rawAudioExt = selected.audioFormat.ext || '.webm';
      const tempAudioExt = rawAudioExt.startsWith('.') ? rawAudioExt : `.${rawAudioExt}`;
      tempAudioPath = path.join(tempDir, `${taskId}-audio${tempAudioExt}`);
      
      task.state = 'downloading_audio';
      task.progress = 0;

      await downloadManager.downloadStream(task.url, selected.audioFormat.formatId, tempAudioPath, (progress) => {
        task.progress = progress;
      });

      task.state = 'merging';
      task.progress = 0;
      finalPath = path.join(downloadsDir, task.filename);

      await mergeService.convertToMp3(tempAudioPath, finalPath);

    } else if (selected.videoFormat && !selected.audioFormat) {
      finalPath = path.join(downloadsDir, task.filename);
      task.state = 'downloading_video';
      task.progress = 0;

      await downloadManager.downloadStream(task.url, selected.videoFormat.formatId, finalPath, (progress) => {
        task.progress = progress;
      });

    } else {
      let rawVideoExt = selected.videoFormat.ext || '.mp4';
      let rawAudioExt = selected.audioFormat.ext || '.webm';
      const tempVideoExt = rawVideoExt.startsWith('.') ? rawVideoExt : `.${rawVideoExt}`;
      const tempAudioExt = rawAudioExt.startsWith('.') ? rawAudioExt : `.${rawAudioExt}`;
      
      tempVideoPath = path.join(tempDir, `${taskId}-video${tempVideoExt}`);
      tempAudioPath = path.join(tempDir, `${taskId}-audio${tempAudioExt}`);

      task.state = 'downloading_video';
      task.progress = 0;
      await downloadManager.downloadStream(task.url, selected.videoFormat.formatId, tempVideoPath, (progress) => {
        task.progress = progress;
      });

      task.state = 'downloading_audio';
      task.progress = 0;
      await downloadManager.downloadStream(task.url, selected.audioFormat.formatId, tempAudioPath, (progress) => {
        task.progress = progress;
      });

      task.state = 'merging';
      task.progress = 0;
      finalPath = path.join(downloadsDir, task.filename);
      await mergeService.mergeStreams(tempVideoPath, tempAudioPath, finalPath);
    }

    if (task.mode !== 'audio') {
      await fileManager.verifyVideoHeight(finalPath, task.expectedHeight || requestedFormat.height);
    }

    fileManager.deleteFile(tempVideoPath);
    fileManager.deleteFile(tempAudioPath);

    task.state = 'completed';
    task.progress = 100;
    task.downloadUrl = `/downloads/${task.filename}`;
    console.log(`Task ${taskId} completed successfully. Served at ${task.downloadUrl}`);

  } catch (error) {
    console.error(`Task ${taskId} failed:`, error);
    task.state = 'failed';
    task.error = error.message;

    fileManager.deleteFile(tempVideoPath);
    fileManager.deleteFile(tempAudioPath);
    if (finalPath && fs.existsSync(finalPath)) {
      fileManager.deleteFile(finalPath);
    }
  }
}

function getTaskStatus(req, res) {
  const { taskId } = req.params;
  const task = tasks[taskId];
  if (!task) {
    return res.status(404).json({ success: false, error: 'Task not found' });
  }
  res.json({ success: true, task });
}

module.exports = {
  getVideoMetadata,
  startDownloadTask,
  getTaskStatus
};
