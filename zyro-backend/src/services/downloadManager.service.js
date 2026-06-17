const youtubedl = require('youtube-dl-exec');

async function downloadStream(url, formatId, outputPath, onProgress) {
  try {
    console.log(`Downloading stream format: ${formatId} to ${outputPath}`);
    
    const child = youtubedl.exec(url, {
      format: formatId,
      output: outputPath,
      noWarnings: true,
      noCacheDir: true,
      noCheckCertificates: true
    });

    if (child.stdout) {
      child.stdout.on('data', (data) => {
        const text = data.toString();
        const match = text.match(/\[download\]\s+(\d+(?:\.\d+)?)%/);
        if (match && onProgress) {
          const pct = parseFloat(match[1]);
          onProgress(pct);
        }
      });
    }

    await new Promise((resolve, reject) => {
      child.on('close', (code) => {
        if (code === 0) {
          resolve();
        } else {
          reject(new Error(`yt-dlp exited with code ${code}`));
        }
      });
      child.on('error', reject);
    });
  } catch (error) {
    console.error('Download stream error:', error);
    throw error;
  }
}

module.exports = { downloadStream };
