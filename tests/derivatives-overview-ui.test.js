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
