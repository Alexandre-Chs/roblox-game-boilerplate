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
