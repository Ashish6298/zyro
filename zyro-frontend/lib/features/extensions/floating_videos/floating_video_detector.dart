class FloatingVideoDetector {
  static String get detectionScript => """
    (function() {
      if (window.zyroFloatingDetectorStarted) return;
      window.zyroFloatingDetectorStarted = true;

      // Define controls namespace for Flutter to call
      window.zyroFloatingController = {
        play: function(selector) {
          try {
            let v = document.querySelector(selector || 'video');
            if (v) v.play();
          } catch(e) { console.error("Floating Video play error: " + e); }
        },
        pause: function(selector) {
          try {
            let v = document.querySelector(selector || 'video');
            if (v) v.pause();
          } catch(e) { console.error("Floating Video pause error: " + e); }
        },
        setSpeed: function(selector, rate) {
          try {
            let v = document.querySelector(selector || 'video');
            if (v) v.playbackRate = parseFloat(rate);
          } catch(e) { console.error("Floating Video setSpeed error: " + e); }
        },
        seek: function(selector, time) {
          try {
            let v = document.querySelector(selector || 'video');
            if (v) v.currentTime = parseFloat(time);
          } catch(e) { console.error("Floating Video seek error: " + e); }
        }
      };

      function isElementVisible(el) {
        if (!el) return false;
        const rect = el.getBoundingClientRect();
        const style = window.getComputedStyle(el);
        return (
          rect.width >= 50 &&
          rect.height >= 50 &&
          style.display !== 'none' &&
          style.visibility !== 'hidden' &&
          style.opacity !== '0' &&
          el.offsetWidth > 0 &&
          el.offsetHeight > 0
        );
      }

      function isYoutubeAd() {
        return !!document.querySelector('.ad-showing, .ad-interrupting, .ytp-ad-player-overlay');
      }

      function getUniqueSelector(el) {
        if (!el) return 'video';
        if (el.id) return '#' + el.id;
        if (el.className) {
          const classes = Array.from(el.classList).join('.');
          if (classes) return el.tagName.toLowerCase() + '.' + classes;
        }
        return 'video';
      }

      function getThumbnail() {
        const video = document.querySelector('video');
        if (video && video.poster) return video.poster;
        const ogImg = document.querySelector('meta[property="og:image"]');
        if (ogImg && ogImg.content) return ogImg.content;
        return '';
      }

      function sendVideoState(video, isPlayingEvent) {
        const visible = isElementVisible(video);
        const isAd = isYoutubeAd();
        
        // Muted autoplay videos at currentTime = 0 are generally not user-played.
        const played = video.played && video.played.length > 0;
        if (!played && video.currentTime === 0) return;

        const rect = video.getBoundingClientRect();
        const title = document.title || 'Floating Video';
        const cleanTitle = title.replace(" - YouTube", "");
        const hostname = window.location.hostname.replace('www.', '');
        const selector = getUniqueSelector(video);

        window.flutter_inappwebview.callHandler('floatingVideoState', {
          'pageUrl': window.location.href,
          'videoTitle': cleanTitle,
          'currentTime': isNaN(video.currentTime) ? 0.0 : video.currentTime,
          'duration': isNaN(video.duration) ? 0.0 : video.duration,
          'isPlaying': isPlayingEvent !== undefined ? isPlayingEvent : !video.paused,
          'isPaused': video.paused,
          'ended': video.ended,
          'videoElementSelector': selector,
          'thumbnail': getThumbnail(),
          'sourceDomain': hostname,
          'playbackRate': video.playbackRate || 1.0,
          'videoWidth': video.videoWidth || 0,
          'videoHeight': video.videoHeight || 0,
          'boundingRect': {
            'x': rect.left,
            'y': rect.top,
            'width': rect.width,
            'height': rect.height
          },
          'isVisible': visible,
          'isAd': isAd
        });
      }

      function setupVideoListeners(video) {
        if (video.zyroFloatingListeners) return;
        video.zyroFloatingListeners = true;

        const events = ['play', 'pause', 'timeupdate', 'durationchange', 'ratechange', 'ended'];
        events.forEach(event => {
          video.addEventListener(event, function() {
            const isPlay = event === 'play' ? true : (event === 'pause' || event === 'ended' ? false : !video.paused);
            sendVideoState(video, isPlay);
          });
        });
      }

      // Periodically scan for active videos and attach listeners
      setInterval(function() {
        try {
          const videos = document.querySelectorAll('video');
          videos.forEach(video => {
            setupVideoListeners(video);
            if (!video.paused && !video.muted) {
              sendVideoState(video);
            }
          });
        } catch(e) {}
      }, 1000);
    })();
  """;
}
