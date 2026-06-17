function sanitizeSingleVideoUrl(url) {
  if (!url) return url;
  if (url.startsWith('blob:')) {
    url = url.replace('blob:', '');
  }
  try {
    const parsed = new URL(url);
    const hostname = parsed.hostname.toLowerCase();

    if (hostname.includes('youtube.com') || hostname.includes('youtu.be')) {
      let videoId = null;

      if (hostname.includes('youtu.be')) {
        // format is youtu.be/VIDEO_ID
        videoId = parsed.pathname.substring(1);
      } else {
        // format is youtube.com/watch?v=VIDEO_ID
        videoId = parsed.searchParams.get('v');
        if (!videoId && parsed.pathname.startsWith('/embed/')) {
          videoId = parsed.pathname.split('/')[2];
        } else if (!videoId && parsed.pathname.startsWith('/shorts/')) {
          videoId = parsed.pathname.split('/')[2];
        }
      }

      if (videoId) {
        // Strip out any additional characters like query parameters from youtu.be path
        const cleanId = videoId.split('?')[0].split('&')[0];
        return `https://www.youtube.com/watch?v=${cleanId}`;
      }
    }
    
    // For other URLs, strip query parameters that look like playlists or autoplay
    const playlistParams = ['list', 'index', 'start_radio', 'autoplay', 'playlist'];
    playlistParams.forEach(param => {
      if (parsed.searchParams.has(param)) {
        parsed.searchParams.delete(param);
      }
    });

    return parsed.toString();
  } catch (e) {
    return url;
  }
}

module.exports = {
  sanitizeSingleVideoUrl
};
