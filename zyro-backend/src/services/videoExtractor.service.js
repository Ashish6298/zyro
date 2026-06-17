const youtubedl = require('youtube-dl-exec');
const { sanitizeSingleVideoUrl } = require('./urlSanitizer.service');

async function extractMetadata(url) {
  try {
    const cleanUrl = sanitizeSingleVideoUrl(url);
    console.log(`Extracting metadata for URL: ${cleanUrl}`);
    const rawData = await youtubedl(cleanUrl, {
      dumpSingleJson: true,
      noWarnings: true,
      preferFreeFormats: true,
      noPlaylist: true,
      noCacheDir: true,
      noCheckCertificates: true,
    });

    // Check if the metadata contains multiple entries (playlist response)
    if (rawData._type === 'playlist' || rawData.entries) {
      throw new Error('Playlist downloads are not supported.');
    }

    const formats = (rawData.formats || []).map(f => {
      const hasVideo = f.vcodec !== 'none' && !!f.vcodec;
      const hasAudio = f.acodec !== 'none' && !!f.acodec;
      const isProgressive = hasVideo && hasAudio;

      return {
        formatId: f.format_id,
        url: f.url,
        ext: f.ext,
        height: f.height || null,
        fps: f.fps || null,
        vcodec: f.vcodec || 'none',
        acodec: f.acodec || 'none',
        bitrate: f.tbr || f.vbr || f.abr || null,
        filesize: f.filesize || f.filesize_approx || null,
        hasAudio,
        hasVideo,
        isProgressive,
        container: f.container || f.ext || 'unknown'
      };
    });

    return {
      title: rawData.title || 'Video',
      thumbnail: rawData.thumbnail || (rawData.thumbnails && rawData.thumbnails.length > 0 ? rawData.thumbnails[rawData.thumbnails.length - 1].url : ''),
      duration: rawData.duration || 0,
      formats
    };
  } catch (error) {
    console.error('Extraction error:', error);
    throw new Error('Failed to extract video metadata: ' + error.message);
  }
}

module.exports = { extractMetadata };
