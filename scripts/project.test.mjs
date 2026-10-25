import { test } from 'node:test';
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { readFileSync, readdirSync, existsSync, realpathSync } from 'node:fs';
import { resolve } from 'node:path';

test('unknown commands fail rather than silently succeeding', () => {
  const result = spawnSync(process.execPath, ['scripts/project.mjs', 'invalid'], { encoding: 'utf8' });
  assert.equal(result.status, 1);
  assert.match(result.stderr, /Unknown command/);
});
test('Claude and Codex discover the same local skill pack', () => {
  assert.equal(realpathSync('.claude/skills'), realpathSync('.agents/skills'));
  for (const name of readdirSync('.agents/skills')) {
    const text = readFileSync(`.agents/skills/${name}/SKILL.md`, 'utf8');
    assert.match(text, new RegExp(`^---\\r?\\nname: ${name}\\r?\\n`));
    assert.match(text, /\ndescription: .+/);
  }
});
test('every Rojo source path exists', () => {
  const project = JSON.parse(readFileSync('default.project.json', 'utf8'));
  function walk(value) {
    if (!value || typeof value !== 'object') return;
    if (value.$path) assert.ok(existsSync(resolve(value.$path)), value.$path);
    Object.values(value).forEach(walk);
  }
  walk(project.tree);
});
test('publish refuses before any network call when misconfigured', () => {
  const run = (...args) => spawnSync(process.execPath, ['scripts/project.mjs', 'publish', ...args], { encoding: 'utf8', env: { ...process.env, ROBLOX_API_KEY: '' } });
  assert.match(run().stderr, /Usage/);
  assert.match(run('staging').stderr, /Usage/);
  const places = JSON.parse(readFileSync('places.json', 'utf8'));
  for (const target of Object.keys(places)) {
    const ready = places[target].universeId && places[target].placeId;
    const result = run(target);
    assert.equal(result.status, 1);
    assert.match(result.stderr, ready ? (target === 'prod' ? /confirm-prod/ : /ROBLOX_API_KEY/) : /places\.json/);
  }
});
