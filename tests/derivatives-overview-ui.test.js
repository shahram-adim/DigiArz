'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const html = fs.readFileSync(path.join(__dirname, '../index.html'), 'utf8');
const matches = [...html.matchAll(/<section\b[^>]*\bid="tab-derivatives"[^>]*>[\s\S]*?<\/section>/g)];

test('Derivatives overview is reachable from desktop and mobile navigation', () => {
  assert.equal(matches.length, 1, 'there must be exactly one Derivatives panel');
  assert.match(html, /<button data-tab="derivatives">[\s\S]*?مشتقات[\s\S]*?<\/button>/);
  assert.match(html, /<button type="button" data-tab="derivatives">[\s\S]*?مشتقات[\s\S]*?<\/button>/);
  assert.match(html, /\['dashboard','markets','toman','derivatives','trade'/);
});

test('Derivatives overview remains read-only until backend and policy gates are approved', () => {
  const panel = matches[0][0];
  assert.match(panel, /معاملات مشتقه/);
  assert.match(panel, /ثبت سفارش، اهرم، وام‌گیری و لیکوییدیشن فعال نیستند/);
  assert.match(panel, /هیچ عملیات مالی از این صفحه انجام نمی‌شود/);
  assert.doesNotMatch(panel, /<form\b|<input\b|<select\b|<button\b/i);
  assert.doesNotMatch(panel, /supabaseClient|\.rpc\s*\(/i);
  assert.match(panel, /قیمت بازار Spot/);
});

test('Android bottom navigation allocates a responsive slot for Derivatives', () => {
  assert.match(html, /\.mobile-bottom-nav\{grid-template-columns:repeat\(7,minmax\(0,1fr\)\)/);
  assert.match(html, /#tab-derivatives \.detail-section/);
});

test('Derivatives overview shows informational Spot quotes without treating them as a risk oracle', () => {
  assert.match(html, /id="derivativesSpotQuotes"/);
  assert.match(html, /id="derivativesSpotQuoteStatus"/);
  assert.match(html, /function renderDerivativesMarketPreview\(\)/);
  assert.match(html, /getTrustedMarketPrice\(item\)/);
  assert.match(html, /renderDashboardMarketPreview\(\);renderDerivativesMarketPreview\(\);renderTopGainers\(\)/);
  assert.match(html, /مرجع Mark\/Index یا محاسبهٔ ریسک و لیکوییدیشن مشتقات نیستند/);
  const start = html.indexOf('function renderDerivativesMarketPreview()');
  const end = html.indexOf('\nfunction renderDashboardSummary()', start);
  assert.ok(start >= 0 && end > start, 'Spot quote renderer must be isolated');
  const renderer = html.slice(start, end);
  assert.doesNotMatch(renderer, /\.rpc\s*\(|\.insert\s*\(|\.update\s*\(|\.delete\s*\(/);
});


test('Derivatives workspace contains the five planned read-only terminal views', () => {
  const start = html.indexOf('id="derivativesWorkspace"');
  const workspace = html.slice(start, html.indexOf('<section id="tab-dashboard"', start));
  assert.ok(start >= 0 && workspace.length > 0);
  for (const view of ['futures','margin','positions','orders','history']) {
    assert.match(workspace, new RegExp('data-deriv-tab="' + view + '"'));
    assert.match(workspace, new RegExp('data-deriv-panel="' + view + '"'));
  }
  assert.match(workspace, /ثبت سفارش آزمایشی — فعلاً غیرفعال/);
  assert.match(workspace, /وام‌گیری یا بازپرداخت — غیرفعال/);
  assert.match(workspace, /مرجع Mark\/Index یا محاسبهٔ ریسک و لیکوییدیشن مشتقات نیست/);
});

test('Derivatives UI prototype cannot write to Supabase or activate financial controls', () => {
  const start = html.indexOf('id="derivativesWorkspace"');
  const end = html.indexOf('<section id="tab-dashboard"', start);
  const workspace = html.slice(start, end);
  assert.doesNotMatch(workspace, /supabaseClient|\.rpc\s*\(|\.insert\s*\(|\.update\s*\(|\.delete\s*\(/i);
  assert.match(workspace, /<button[^>]*disabled/);
  assert.match(workspace, /<select[^>]*disabled/);
  assert.match(workspace, /<input[^>]*disabled/);
});
