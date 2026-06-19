class DevToolsService {
  static const String highlightScript = """
    (function(selector) {
      var existing = document.getElementById('zyro-devtools-highlight');
      if (existing) existing.remove();

      var el = document.querySelector(selector);
      if (!el) return false;

      var rect = el.getBoundingClientRect();
      var highlight = document.createElement('div');
      highlight.id = 'zyro-devtools-highlight';
      highlight.style.position = 'absolute';
      highlight.style.left = (rect.left + window.scrollX) + 'px';
      highlight.style.top = (rect.top + window.scrollY) + 'px';
      highlight.style.width = rect.width + 'px';
      highlight.style.height = rect.height + 'px';
      highlight.style.border = '2px dashed #00F0FF';
      highlight.style.backgroundColor = 'rgba(0, 240, 255, 0.15)';
      highlight.style.pointerEvents = 'none';
      highlight.style.zIndex = '2147483647';
      highlight.style.transition = 'all 0.3s ease';
      
      document.body.appendChild(highlight);

      // Flash effect
      var opacity = 0.15;
      var interval = setInterval(function() {
        opacity = opacity === 0.15 ? 0.35 : 0.15;
        highlight.style.backgroundColor = 'rgba(0, 240, 255, ' + opacity + ')';
      }, 500);

      setTimeout(function() {
        clearInterval(interval);
        if (highlight.parentNode) {
          highlight.parentNode.removeChild(highlight);
        }
      }, 4000);
      return true;
    })
  """;

  static const String getElementInfoScript = """
    (function() {
      var el = window.lastContextMenuTarget;
      if (!el) {
        var x = window.lastTouchX || 0;
        var y = window.lastTouchY || 0;
        el = document.elementFromPoint(x, y);
      }
      if (!el) return null;

      // Unique CSS selector generator
      function getUniqueSelector(element) {
        if (!element || element.nodeType !== 1) return '';
        var path = [];
        while (element && element.nodeType === 1) {
          var name = element.localName;
          if (!name) break;
          name = name.toLowerCase();
          if (element.id) {
            path.unshift('#' + element.id);
            break;
          } else {
            var sib = element, cnt = 1;
            while (sib = sib.previousElementSibling) {
              if (sib.localName.toLowerCase() == name) cnt++;
            }
            if (cnt > 1) name += ':nth-of-type(' + cnt + ')';
          }
          path.unshift(name);
          element = element.parentNode;
        }
        return path.join(' > ');
      }

      // Attributes
      var attrs = {};
      for (var i = 0; i < el.attributes.length; i++) {
        var a = el.attributes[i];
        attrs[a.name] = a.value;
      }

      // Selected styles
      var computed = window.getComputedStyle(el);
      var styles = {};
      var styleKeys = ['display', 'position', 'color', 'background-color', 'font-size', 'font-family', 'width', 'height', 'margin', 'padding', 'z-index', 'opacity', 'flex-direction', 'justify-content', 'align-items'];
      for (var k of styleKeys) {
        styles[k] = computed.getPropertyValue(k) || '';
      }

      // Parent hierarchy
      var parents = [];
      var curr = el.parentNode;
      while (curr && curr.nodeType === 1 && curr.tagName !== 'HTML') {
        var desc = curr.tagName.toLowerCase();
        if (curr.id) desc += '#' + curr.id;
        else if (curr.className) desc += '.' + curr.className.split(' ').join('.');
        parents.push(desc);
        curr = curr.parentNode;
      }

      var rect = el.getBoundingClientRect();

      return {
        "selector": getUniqueSelector(el),
        "tagName": el.tagName.toLowerCase(),
        "id": el.id || "",
        "className": el.className || "",
        "textContent": el.textContent || el.innerText || "",
        "href": el.getAttribute('href') || el.href || null,
        "src": el.getAttribute('src') || el.src || null,
        "outerHTML": el.outerHTML || "",
        "attributes": attrs,
        "styles": styles,
        "parentHierarchy": parents,
        "boundingBox": {
          "x": rect.x || rect.left,
          "y": rect.y || rect.top,
          "width": rect.width,
          "height": rect.height,
          "top": rect.top,
          "bottom": rect.bottom,
          "left": rect.left,
          "right": rect.right
        }
      };
    })()
  """;

  static const String getDomTreeScript = """
    (function(selector) {
      var root = selector ? document.querySelector(selector) : document.body;
      if (!root) return null;

      function nodeToJSON(node) {
        if (node.nodeType !== 1) return null; // Only Element nodes
        
        var attributes = {};
        for (var i = 0; i < node.attributes.length; i++) {
          var a = node.attributes[i];
          attributes[a.name] = a.value;
        }

        var children = [];
        var childNodes = node.childNodes;
        for (var i = 0; i < childNodes.length; i++) {
          var c = childNodes[i];
          if (c.nodeType === 1) { // Element
            children.push(nodeToJSON(c));
          } else if (c.nodeType === 3) { // Text
            var text = c.textContent.trim();
            if (text.length > 0) {
              children.push({
                "type": "text",
                "textContent": text
              });
            }
          }
        }

        return {
          "type": "element",
          "tagName": node.tagName.toLowerCase(),
          "id": node.id || "",
          "className": node.className || "",
          "attributes": attributes,
          "children": children
        };
      }

      return nodeToJSON(root);
    })
  """;

  static const String getStorageScript = """
    (function() {
      // Cookies
      var cookies = [];
      var cookieParts = document.cookie.split(';');
      for (var i = 0; i < cookieParts.length; i++) {
        var p = cookieParts[i].trim();
        if (p.indexOf('=') !== -1) {
          var parts = p.split('=');
          cookies.push({
            "key": parts[0],
            "value": decodeURIComponent(parts[1] || '')
          });
        }
      }

      // LocalStorage
      var local = [];
      for (var i = 0; i < localStorage.length; i++) {
        var k = localStorage.key(i);
        local.push({
          "key": k,
          "value": localStorage.getItem(k) || ''
        });
      }

      // SessionStorage
      var session = [];
      for (var i = 0; i < sessionStorage.length; i++) {
        var k = sessionStorage.key(i);
        session.push({
          "key": k,
          "value": sessionStorage.getItem(k) || ''
        });
      }

      return {
        "cookies": cookies,
        "localStorage": local,
        "sessionStorage": session
      };
    })()
  """;

  static const String getResourcesScript = """
    (function() {
      var resources = [];

      // Scripts
      var scripts = document.getElementsByTagName('script');
      for (var i = 0; i < scripts.length; i++) {
        var s = scripts[i];
        if (s.src) {
          resources.push({
            "url": s.src,
            "type": "script",
            "name": s.src.split('/').pop().split('?')[0] || "script.js"
          });
        }
      }

      // Stylesheets
      var links = document.getElementsByTagName('link');
      for (var i = 0; i < links.length; i++) {
        var l = links[i];
        if (l.rel === 'stylesheet' && l.href) {
          resources.push({
            "url": l.href,
            "type": "stylesheet",
            "name": l.href.split('/').pop().split('?')[0] || "style.css"
          });
        }
      }

      // Images
      var imgs = document.getElementsByTagName('img');
      for (var i = 0; i < imgs.length; i++) {
        var im = imgs[i];
        if (im.src) {
          resources.push({
            "url": im.src,
            "type": "image",
            "name": im.src.split('/').pop().split('?')[0] || "image"
          });
        }
      }

      // Videos / Audios
      var media = [];
      var videos = document.getElementsByTagName('video');
      for (var i = 0; i < videos.length; i++) {
        var v = videos[i];
        if (v.src) {
          resources.push({
            "url": v.src,
            "type": "media",
            "name": v.src.split('/').pop().split('?')[0] || "video"
          });
        }
      }
      var audios = document.getElementsByTagName('audio');
      for (var i = 0; i < audios.length; i++) {
        var a = audios[i];
        if (a.src) {
          resources.push({
            "url": a.src,
            "type": "media",
            "name": a.src.split('/').pop().split('?')[0] || "audio"
          });
        }
      }

      return resources;
    })()
  """;
}
