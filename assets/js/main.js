/* =====================================================================
   Md. Nafis Salman - Portfolio interactions
   Vanilla JS, no dependencies. Each feature is isolated in its own
   init function and guarded so a missing element never breaks the rest.
   ---------------------------------------------------------------------
   1.  Theme toggle (persisted in localStorage)
   2.  Sticky header + scroll progress bar
   3.  Mobile navigation
   4.  Active nav link highlighting
   5.  Reveal-on-scroll animations
   6.  Skill meter fill animation
   7.  Stat counters
   8.  Typewriter effect for the hero role
   9.  Back-to-top button
   10. Contact form validation -> mailto handoff
   11. Footer year
   ===================================================================== */
(function () {
  'use strict';

  var root = document.documentElement;
  var prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  /* ---------------------------------------------------------------- */
  /* 1. Theme toggle                                                   */
  /* ---------------------------------------------------------------- */
  var THEME_KEY = 'nafis-portfolio-theme';

  function readStoredTheme() {
    try {
      return window.localStorage.getItem(THEME_KEY);
    } catch (err) {
      return null; // private mode / storage disabled
    }
  }

  function storeTheme(value) {
    try {
      window.localStorage.setItem(THEME_KEY, value);
    } catch (err) {
      /* ignore - theme simply will not persist */
    }
  }

  function applyTheme(theme, button) {
    root.setAttribute('data-theme', theme);

    var meta = document.querySelector('meta[name="theme-color"]');
    if (meta) {
      meta.setAttribute('content', theme === 'light' ? '#f5f7fb' : '#0a0f1a');
    }

    if (button) {
      var toLight = theme === 'dark';
      button.setAttribute('aria-pressed', String(theme === 'light'));
      button.setAttribute('aria-label', toLight ? 'Switch to light theme' : 'Switch to dark theme');
      button.setAttribute('title', toLight ? 'Switch to light theme' : 'Switch to dark theme');
    }
  }

  function initTheme() {
    var button = document.getElementById('theme-toggle');
    var stored = readStoredTheme();
    var systemLight = window.matchMedia('(prefers-color-scheme: light)').matches;
    var initial = stored || (systemLight ? 'light' : 'dark');

    applyTheme(initial, button);
    if (!button) { return; }

    button.addEventListener('click', function () {
      var next = root.getAttribute('data-theme') === 'light' ? 'dark' : 'light';
      applyTheme(next, button);
      storeTheme(next);
    });
  }

  /* ---------------------------------------------------------------- */
  /* 2. Sticky header + scroll progress                                */
  /* ---------------------------------------------------------------- */
  function initHeaderOnScroll() {
    var header = document.getElementById('site-header');
    var progress = document.getElementById('scroll-progress');
    var toTop = document.getElementById('to-top');
    var ticking = false;

    function update() {
      var scrolled = window.pageYOffset || root.scrollTop;

      if (header) {
        header.classList.toggle('is-stuck', scrolled > 12);
      }

      if (progress) {
        var max = root.scrollHeight - window.innerHeight;
        var pct = max > 0 ? (scrolled / max) * 100 : 0;
        progress.style.width = Math.min(100, Math.max(0, pct)) + '%';
      }

      if (toTop) {
        toTop.classList.toggle('is-visible', scrolled > 500);
      }

      ticking = false;
    }

    function onScroll() {
      if (ticking) { return; }
      ticking = true;
      window.requestAnimationFrame(update);
    }

    window.addEventListener('scroll', onScroll, { passive: true });
    window.addEventListener('resize', onScroll);
    update();
  }

  /* ---------------------------------------------------------------- */
  /* 3. Mobile navigation                                              */
  /* ---------------------------------------------------------------- */
  function initMobileNav() {
    var toggle = document.getElementById('nav-toggle');
    var nav = document.getElementById('primary-nav');
    if (!toggle || !nav) { return; }

    function close() {
      nav.classList.remove('is-open');
      toggle.setAttribute('aria-expanded', 'false');
      toggle.setAttribute('aria-label', 'Open navigation menu');
    }

    function open() {
      nav.classList.add('is-open');
      toggle.setAttribute('aria-expanded', 'true');
      toggle.setAttribute('aria-label', 'Close navigation menu');
    }

    toggle.addEventListener('click', function () {
      if (nav.classList.contains('is-open')) { close(); } else { open(); }
    });

    // Close after picking a destination
    nav.addEventListener('click', function (event) {
      if (event.target.closest('a')) { close(); }
    });

    document.addEventListener('keydown', function (event) {
      if (event.key === 'Escape' && nav.classList.contains('is-open')) {
        close();
        toggle.focus();
      }
    });

    window.addEventListener('resize', function () {
      if (window.innerWidth > 860) { close(); }
    });
  }

  /* ---------------------------------------------------------------- */
  /* 4. Active nav link highlighting                                   */
  /* ---------------------------------------------------------------- */
  function initActiveNav() {
    var links = Array.prototype.slice.call(document.querySelectorAll('.nav-link'));
    if (!links.length) { return; }

    var sections = links
      .map(function (link) {
        var id = link.getAttribute('href');
        return id && id.charAt(0) === '#' ? document.querySelector(id) : null;
      })
      .filter(Boolean);

    if (!sections.length) { return; }

    function setActive(id) {
      links.forEach(function (link) {
        link.classList.toggle('is-active', link.getAttribute('href') === '#' + id);
      });
    }

    if (!('IntersectionObserver' in window)) { return; }

    var observer = new IntersectionObserver(function (entries) {
      // Pick the entry closest to the top of the viewport that is visible
      var best = null;
      entries.forEach(function (entry) {
        if (!entry.isIntersecting) { return; }
        if (!best || entry.boundingClientRect.top < best.boundingClientRect.top) {
          best = entry;
        }
      });
      if (best) { setActive(best.target.id); }
    }, {
      rootMargin: '-45% 0px -50% 0px',
      threshold: 0
    });

    sections.forEach(function (section) { observer.observe(section); });
  }

  /* ---------------------------------------------------------------- */
  /* 5. Reveal on scroll                                               */
  /* ---------------------------------------------------------------- */
  function initReveal() {
    var items = Array.prototype.slice.call(document.querySelectorAll('[data-reveal]'));
    if (!items.length) { return; }

    if (prefersReducedMotion || !('IntersectionObserver' in window)) {
      items.forEach(function (item) { item.classList.add('is-revealed'); });
      return;
    }

    var observer = new IntersectionObserver(function (entries, obs) {
      entries.forEach(function (entry) {
        if (!entry.isIntersecting) { return; }

        var target = entry.target;
        var siblings = target.parentElement
          ? Array.prototype.slice.call(target.parentElement.children).filter(function (el) {
              return el.hasAttribute('data-reveal');
            })
          : [target];
        var index = Math.max(0, siblings.indexOf(target));

        target.style.transitionDelay = Math.min(index * 80, 320) + 'ms';
        target.classList.add('is-revealed');
        obs.unobserve(target);
      });
    }, { rootMargin: '0px 0px -10% 0px', threshold: 0.12 });

    items.forEach(function (item) { observer.observe(item); });
  }

  /* ---------------------------------------------------------------- */
  /* 6. Skill meters                                                   */
  /* ---------------------------------------------------------------- */
  function initMeters() {
    var meters = Array.prototype.slice.call(document.querySelectorAll('.meter'));
    if (!meters.length) { return; }

    function fill(meter) {
      var level = parseInt(meter.getAttribute('data-level'), 10);
      if (isNaN(level)) { level = 0; }
      level = Math.min(100, Math.max(0, level));

      var bar = meter.querySelector('i');
      if (bar) { bar.style.width = level + '%'; }

      // Expose the value to assistive tech
      meter.setAttribute('role', 'meter');
      meter.setAttribute('aria-valuemin', '0');
      meter.setAttribute('aria-valuemax', '100');
      meter.setAttribute('aria-valuenow', String(level));
    }

    if (!('IntersectionObserver' in window)) {
      meters.forEach(fill);
      return;
    }

    var observer = new IntersectionObserver(function (entries, obs) {
      entries.forEach(function (entry) {
        if (!entry.isIntersecting) { return; }
        fill(entry.target);
        obs.unobserve(entry.target);
      });
    }, { threshold: 0.4 });

    meters.forEach(function (meter) { observer.observe(meter); });
  }


  /* ---------------------------------------------------------------- */
  /* 7. Stat counters                                                  */
  /* ---------------------------------------------------------------- */
  function initCounters() {
    var counters = Array.prototype.slice.call(document.querySelectorAll('.counter'));
    if (!counters.length) { return; }

    function run(el) {
      var target = parseInt(el.getAttribute('data-count-to'), 10);
      if (isNaN(target)) { return; }

      if (prefersReducedMotion) {
        el.textContent = String(target);
        return;
      }

      var duration = 1100;
      var start = null;

      function step(timestamp) {
        if (start === null) { start = timestamp; }
        var progress = Math.min(1, (timestamp - start) / duration);
        // easeOutCubic
        var eased = 1 - Math.pow(1 - progress, 3);
        el.textContent = String(Math.round(target * eased));
        if (progress < 1) { window.requestAnimationFrame(step); }
      }

      window.requestAnimationFrame(step);
    }

    if (!('IntersectionObserver' in window)) {
      counters.forEach(run);
      return;
    }

    var observer = new IntersectionObserver(function (entries, obs) {
      entries.forEach(function (entry) {
        if (!entry.isIntersecting) { return; }
        run(entry.target);
        obs.unobserve(entry.target);
      });
    }, { threshold: 0.5 });

    counters.forEach(function (counter) { observer.observe(counter); });
  }

  /* ---------------------------------------------------------------- */
  /* 8. Typewriter for the hero role                                   */
  /* ---------------------------------------------------------------- */
  function initTyped() {
    var el = document.getElementById('typed');
    if (!el) { return; }

    var phrases = [
      'Engineer, Incident Responder',
      'Cyber Security Practitioner',
      'SOC Analyst (CSA)',
      'Certified Ethical Hacker (CEHv12)',
      'Vulnerability Assessment Specialist'
    ];

    if (prefersReducedMotion) {
      el.textContent = phrases[0];
      return;
    }

    var TYPE_SPEED = 65;
    var ERASE_SPEED = 32;
    var HOLD = 1500;

    var phraseIndex = 0;
    var charIndex = 0;
    var erasing = false;

    function tick() {
      var phrase = phrases[phraseIndex];

      if (!erasing) {
        charIndex += 1;
        el.textContent = phrase.slice(0, charIndex);

        if (charIndex === phrase.length) {
          erasing = true;
          window.setTimeout(tick, HOLD);
          return;
        }
        window.setTimeout(tick, TYPE_SPEED);
        return;
      }

      charIndex -= 1;
      el.textContent = phrase.slice(0, charIndex);

      if (charIndex === 0) {
        erasing = false;
        phraseIndex = (phraseIndex + 1) % phrases.length;
        window.setTimeout(tick, 320);
        return;
      }
      window.setTimeout(tick, ERASE_SPEED);
    }

    window.setTimeout(tick, 500);
  }

  /* ---------------------------------------------------------------- */
  /* 9. Back to top                                                    */
  /* ---------------------------------------------------------------- */
  function initToTop() {
    var button = document.getElementById('to-top');
    if (!button) { return; }

    button.addEventListener('click', function () {
      window.scrollTo({
        top: 0,
        behavior: prefersReducedMotion ? 'auto' : 'smooth'
      });
    });
  }


  /* ---------------------------------------------------------------- */
  /* 10. Contact form -> mailto handoff                                */
  /* ---------------------------------------------------------------- */
  function initContactForm() {
    var form = document.getElementById('contact-form');
    if (!form) { return; }

    var OWNER_EMAIL = 'nafissalman.cse@gmail.com';
    var status = document.getElementById('form-status');
    var EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/;

    var fields = [
      { id: 'cf-name', label: 'name', min: 2 },
      { id: 'cf-email', label: 'email', min: 5 },
      { id: 'cf-subject', label: 'subject', min: 3 },
      { id: 'cf-message', label: 'message', min: 10 }
    ];

    function setFieldError(input, message) {
      var wrapper = input.closest('.field');
      var errorEl = document.getElementById(input.id + '-error');

      if (wrapper) { wrapper.classList.toggle('has-error', Boolean(message)); }
      if (errorEl) { errorEl.textContent = message || ''; }
      input.setAttribute('aria-invalid', message ? 'true' : 'false');
    }

    function validateField(config) {
      var input = document.getElementById(config.id);
      if (!input) { return true; }

      var value = input.value.trim();

      if (!value) {
        setFieldError(input, 'Please enter your ' + config.label + '.');
        return false;
      }
      if (value.length < config.min) {
        setFieldError(input, 'Your ' + config.label + ' looks too short.');
        return false;
      }
      if (config.label === 'email' && !EMAIL_RE.test(value)) {
        setFieldError(input, 'Please enter a valid email address.');
        return false;
      }

      setFieldError(input, '');
      return true;
    }

    // Live feedback once a field has been touched
    fields.forEach(function (config) {
      var input = document.getElementById(config.id);
      if (!input) { return; }

      input.addEventListener('blur', function () { validateField(config); });
      input.addEventListener('input', function () {
        var wrapper = input.closest('.field');
        if (wrapper && wrapper.classList.contains('has-error')) { validateField(config); }
      });
    });

    form.addEventListener('submit', function (event) {
      event.preventDefault();

      var valid = true;
      var firstInvalid = null;

      fields.forEach(function (config) {
        var ok = validateField(config);
        if (!ok && !firstInvalid) { firstInvalid = document.getElementById(config.id); }
        valid = valid && ok;
      });

      if (!valid) {
        if (status) {
          status.textContent = 'Please fix the highlighted fields.';
          status.classList.add('is-error');
        }
        if (firstInvalid) { firstInvalid.focus(); }
        return;
      }

      var name = document.getElementById('cf-name').value.trim();
      var email = document.getElementById('cf-email').value.trim();
      var subject = document.getElementById('cf-subject').value.trim();
      var message = document.getElementById('cf-message').value.trim();

      var body = message + '\n\n--\n' + name + '\n' + email;
      var mailto = 'mailto:' + OWNER_EMAIL +
        '?subject=' + encodeURIComponent(subject) +
        '&body=' + encodeURIComponent(body);

      if (status) {
        status.classList.remove('is-error');
        status.textContent = 'Opening your email client with the message ready to send...';
      }

      window.location.href = mailto;
      form.reset();
    });
  }

  /* ---------------------------------------------------------------- */
  /* 11. Footer year                                                   */
  /* ---------------------------------------------------------------- */
  function initYear() {
    var el = document.getElementById('year');
    if (el) { el.textContent = String(new Date().getFullYear()); }
  }

  /* ---------------------------------------------------------------- */
  /* Bootstrap                                                         */
  /* ---------------------------------------------------------------- */
  function init() {
    initTheme();
    initHeaderOnScroll();
    initMobileNav();
    initActiveNav();
    initReveal();
    initMeters();
    initCounters();
    initTyped();
    initToTop();
    initContactForm();
    initYear();
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
}());

