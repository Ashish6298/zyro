const youtubedl = require('youtube-dl-exec');

async function downloadStream(url, formatId, outputPath, onProgress) {
  try {
    console.log(`Downloading stream format: ${formatId} to ${outputPath}`);
    
    const child = youtubedl.exec(url, {
      format: formatId,
      output: outputPath,
      noWarnings: true,
      noCacheDir: true,
      noCheckCertificates: true,
      // YouTube can reject a single long-lived media request with HTTP 403.
      // Downloading in small ranged chunks refreshes the request throughout
      // the transfer without changing the selected format or output.
      httpChunkSize: '1M'
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

    // youtube-dl-exec returns a thenable child process. Awaiting it handles
    // both non-zero exits and spawn errors, avoiding an unhandled rejection.
    await child;
  } catch (error) {
    console.error('Download stream error:', error);
    throw error;
  }
}

module.exports = { downloadStream };
