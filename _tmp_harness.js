/* =====================================================================
   Temporary verification harness (not part of the site).
   Replaces IntersectionObserver with a shim that fires immediately so the
   scroll-driven features in main.js can be asserted in headless Chrome,
   then prints a JSON report into #test-report.
   ===================================================================== */
(function () {
  'use strict';

  window.__ioObserved = 0;

  function ShimIO(callback) {
    this._cb = callback;
    this._targets = [];
  }
  ShimIO.prototype.observe = function (target) {
    window.__ioObserved += 1;
    this._targets.push(target);
    var entry = {
      target: target,
      isIntersecting: true,
      intersectionRatio: 1,
      boundingClientRect: target.getBoundingClientRect()
    };
    var self = this;
    // async so main.js finishes wiring before callbacks land
    window.setTimeout(function () { self._cb([entry], self); }, 0);
  };
  ShimIO.prototype.unobserve = function () {};
  ShimIO.prototype.disconnect = function () {};
  ShimIO.prototype.takeRecords = function () { return []; };

  window.IntersectionObserver = ShimIO;
  window.IntersectionObserverEntry = function () {};

  /* Headless --dump-dom does not produce compositor frames, so
     requestAnimationFrame never fires past the first callback. Route it
     through setTimeout so rAF-driven code (counters, scroll handler) runs. */
  window.requestAnimationFrame = function (cb) {
    return window.setTimeout(function () { cb(Date.now()); }, 16);
  };
  window.cancelAnimationFrame = function (id) { window.clearTimeout(id); };

  function report() {
    var q = function (sel) { return document.querySelectorAll(sel); };
    var meters = Array.prototype.slice.call(q('.meter'));
    var counters = Array.prototype.slice.call(q('.counter'));

    var data = {
      ioObserved: window.__ioObserved,
      theme: document.documentElement.getAttribute('data-theme'),
      noJsClassRemoved: !document.documentElement.classList.contains('no-js'),
      revealTotal: q('[data-reveal]').length,
      revealed: q('[data-reveal].is-revealed').length,
      metersTotal: meters.length,
      metersFilled: meters.filter(function (m) {
        var bar = m.querySelector('i');
        return bar && bar.style.width && bar.style.width !== '0%';
      }).length,
      meterAria: meters.filter(function (m) { return m.getAttribute('aria-valuenow'); }).length,
      meterValues: meters.map(function (m) { return m.getAttribute('aria-valuenow'); }).join('|'),
      counterValues: counters.map(function (c) { return c.textContent; }).join('|'),
      navActive: q('.nav-link.is-active').length,
      typedText: (document.getElementById('typed') || {}).textContent || '',
      year: (document.getElementById('year') || {}).textContent || '',
      headerStuck: document.getElementById('site-header').classList.contains('is-stuck'),
      progressWidth: document.getElementById('scroll-progress').style.width
    };

    /* ---- form validation: empty submit must block and flag 4 fields ---- */
    var form = document.getElementById('contact-form');
    form.dispatchEvent(new Event('submit', { bubbles: true, cancelable: true }));
    data.emptySubmitErrors = q('.field.has-error').length;
    data.emptySubmitStatus = document.getElementById('form-status').textContent;

    /* ---- bad email must be rejected ---- */
    document.getElementById('cf-name').value = 'Recruiter Name';
    document.getElementById('cf-email').value = 'not-an-email';
    document.getElementById('cf-subject').value = 'Role enquiry';
    document.getElementById('cf-message').value = 'Hello, we have an opening for you.';
    form.dispatchEvent(new Event('submit', { bubbles: true, cancelable: true }));
    data.badEmailErrors = q('.field.has-error').length;
    data.badEmailMessage = document.getElementById('cf-email-error').textContent;

    /* ---- valid input must clear all errors ---- */
    document.getElementById('cf-email').value = 'recruiter@example.com';
    document.getElementById('cf-email').dispatchEvent(new Event('input', { bubbles: true }));
    document.getElementById('cf-email').dispatchEvent(new Event('blur'));
    data.afterFixErrors = q('.field.has-error').length;

    /* ---- theme toggle round trip ---- */
    var toggle = document.getElementById('theme-toggle');
    var before = document.documentElement.getAttribute('data-theme');
    toggle.click();
    var afterFirst = document.documentElement.getAttribute('data-theme');
    toggle.click();
    var afterSecond = document.documentElement.getAttribute('data-theme');
    data.themeToggle = before + '>' + afterFirst + '>' + afterSecond;
    data.themePressed = toggle.getAttribute('aria-pressed');

    /* ---- mobile nav toggle ---- */
    var navToggle = document.getElementById('nav-toggle');
    var nav = document.getElementById('primary-nav');
    navToggle.click();
    data.navOpen = nav.classList.contains('is-open') + '/' + navToggle.getAttribute('aria-expanded');
    nav.querySelector('a').dispatchEvent(new MouseEvent('click', { bubbles: true }));
    data.navClosedAfterLinkClick = (!nav.classList.contains('is-open')) + '/' + navToggle.getAttribute('aria-expanded');

    /* ---- scroll-driven state ---- */
    data.rafFired = window.__rafFired === true;
    data.reducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    window.__rafCount = 0;
    (function loop() {
      window.__rafCount += 1;
      if (window.__rafCount < 400) { window.requestAnimationFrame(loop); }
    }());

    // 'instant' bypasses the smooth-scroll CSS so the offset applies at once
    window.scrollTo({ top: 1400, left: 0, behavior: 'instant' });
    data.pageYOffset = window.pageYOffset;
    data.docScrollHeight = document.documentElement.scrollHeight;
    data.innerHeight = window.innerHeight;
    window.dispatchEvent(new Event('scroll'));

    var pre = document.createElement('pre');
    pre.id = 'test-report';

    // give the rAF-throttled scroll handler time to settle
    window.setTimeout(function () {
      data.rafCount = window.__rafCount;
      data.afterScrollHeaderStuck = document.getElementById('site-header').classList.contains('is-stuck');
      data.afterScrollProgress = document.getElementById('scroll-progress').style.width;
      data.afterScrollToTopVisible = document.getElementById('to-top').classList.contains('is-visible');
      data.counterValuesLate = Array.prototype.slice.call(document.querySelectorAll('.counter'))
        .map(function (c) { return c.textContent; }).join('|');
      data.typedLate = (document.getElementById('typed') || {}).textContent || '';

      pre.textContent = JSON.stringify(data, null, 2);
      document.body.appendChild(pre);
    }, 2500);
  }

  window.requestAnimationFrame(function () { window.__rafFired = true; });

  window.addEventListener('load', function () {
    window.setTimeout(report, 300);
  });
}());
