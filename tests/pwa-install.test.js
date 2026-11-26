'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');

const source = fs.readFileSync('src/pwa-install.js', 'utf8');

function createHarness() {
  const windowListeners = new Map();
  const buttonListeners = new Map();
  const classes = new Set(['hidden']);
  const banner = {
    classList: {
      add(name) { classes.add(name); },
      remove(name) { classes.delete(name); },
      contains(name) { return classes.has(name); }
    }
  };
  const button = {
    disabled: false,
    addEventListener(type, callback) { buttonListeners.set(type, callback); }
  };
  const warnings = [];
  const context = {
    document: {
      getElementById(id) {
        if (id === 'pwaInstallBanner') return banner;
        if (id === 'pwaInstallBtn') return button;
        return null;
      }
    },
    window: {
      addEventListener(type, callback) { windowListeners.set(type, callback); }
    },
    console: { warn(...args) { warnings.push(args); } }
  };
  vm.runInNewContext(source, context, { filename: 'src/pwa-install.js' });
  return { windowListeners, buttonListeners, banner, button, classes, warnings };
}

test('install banner stays hidden until the browser offers an install prompt', () => {
  const h = createHarness();
  assert.equal(h.banner.classList.contains('hidden'), true);
  let prevented = false;
  h.windowListeners.get('beforeinstallprompt')({ preventDefault() { prevented = true; } });
  assert.equal(prevented, true);
  assert.equal(h.banner.classList.contains('hidden'), false);
  assert.equal(h.button.disabled, false);
});

test('install button invokes the browser prompt once and then hides the banner', async () => {
  const h = createHarness();
  let promptCalls = 0;
  h.windowListeners.get('beforeinstallprompt')({
    preventDefault() {},
    async prompt() { promptCalls += 1; },
    userChoice: Promise.resolve({ outcome: 'accepted' })
  });
  await h.buttonListeners.get('click')();
  assert.equal(promptCalls, 1);
  assert.equal(h.banner.classList.contains('hidden'), true);
  assert.equal(h.button.disabled, false);
  await h.buttonListeners.get('click')();
  assert.equal(promptCalls, 1);
});

test('appinstalled event hides the install banner', () => {
  const h = createHarness();
  h.windowListeners.get('beforeinstallprompt')({ preventDefault() {} });
  assert.equal(h.banner.classList.contains('hidden'), false);
  h.windowListeners.get('appinstalled')();
  assert.equal(h.banner.classList.contains('hidden'), true);
});

test('dismissed install prompt is not reused', async () => {
  const h = createHarness();
  let promptCalls = 0;
  h.windowListeners.get('beforeinstallprompt')({
    preventDefault() {},
    async prompt() { promptCalls += 1; },
    userChoice: Promise.resolve({ outcome: 'dismissed' })
  });
  await h.buttonListeners.get('click')();
  await h.buttonListeners.get('click')();
  assert.equal(promptCalls, 1);
  assert.equal(h.banner.classList.contains('hidden'), true);
});


test('failed browser prompt is not reused and hides the banner', async () => {
  const h = createHarness();
  let promptCalls = 0;
  h.windowListeners.get('beforeinstallprompt')({
    preventDefault() {},
    async prompt() {
      promptCalls += 1;
      throw new Error('prompt unavailable');
    },
    userChoice: Promise.resolve({ outcome: 'dismissed' })
  });
  await h.buttonListeners.get('click')();
  await h.buttonListeners.get('click')();
  assert.equal(promptCalls, 1);
  assert.equal(h.banner.classList.contains('hidden'), true);
  assert.equal(h.button.disabled, false);
  assert.equal(h.warnings.length, 1);
});
