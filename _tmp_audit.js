/* Temporary layout audit: reports horizontal overflow offenders and key
   computed styles at the current viewport. Injected after main.js. */
(function () {
  'use strict';

  function audit() {
    var docEl = document.documentElement;
    var vw = docEl.clientWidth;
    var out = {
      viewport: vw + 'x' + docEl.clientHeight,
      scrollWidth: docEl.scrollWidth,
      bodyScrollWidth: document.body.scrollWidth,
      horizontalOverflow: docEl.scrollWidth - vw,
      offenders: []
    };

    var all = document.querySelectorAll('body *');
    for (var i = 0; i < all.length; i++) {
      var el = all[i];
      var cs = window.getComputedStyle(el);
      if (cs.position === 'fixed' || cs.display === 'none' || cs.visibility === 'hidden') { continue; }
      if (el.getAttribute('aria-hidden') === 'true' && cs.position === 'absolute') { continue; }

      var r = el.getBoundingClientRect();
      if (r.width === 0 && r.height === 0) { continue; }

      if (r.right > vw + 1 || r.left < -1) {
        out.offenders.push(
          (el.tagName.toLowerCase() +
           (el.id ? '#' + el.id : '') +
           (el.className && typeof el.className === 'string' ? '.' + el.className.trim().split(/\s+/).join('.') : '')
          ).slice(0, 70) +
          '  left=' + Math.round(r.left) + ' right=' + Math.round(r.right) + ' w=' + Math.round(r.width)
        );
      }
    }
    out.offenderCount = out.offenders.length;
    out.offenders = out.offenders.slice(0, 14);

    var pre = document.createElement('pre');
    pre.id = 'audit-report';
    pre.textContent = JSON.stringify(out, null, 2);
    document.body.appendChild(pre);
  }

  window.addEventListener('load', function () { window.setTimeout(audit, 250); });
}());
