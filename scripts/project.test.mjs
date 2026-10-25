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
test('world models place parts with CFrame, because Rojo ignores a Vector3 Position', () => {
  function walk(node, file) {
    const position = node.Properties?.Position;
    assert.ok(!Array.isArray(position), `${file}: ${node.Name ?? node.ClassName} uses Position; use "CFrame": { "CFrame": { "position": [...], "orientation": [...] } }`);
    (node.Children ?? []).forEach((child) => walk(child, file));
  }
  for (const name of readdirSync('assets/world').filter((f) => f.endsWith('.model.json'))) {
    walk(JSON.parse(readFileSync(`assets/world/${name}`, 'utf8')), name);
  }
});
test('UI models write attributes with the lowercase key Rojo reads', () => {
  // Rojo silently drops a capitalised "Attributes" key in .model.json files.
  function walk(node, file) {
    assert.ok(!('Attributes' in node), `${file}: ${node.Name ?? node.ClassName} uses "Attributes"; Rojo only reads "attributes"`);
    (node.Children ?? []).forEach((child) => walk(child, file));
  }
  for (const dir of ['assets/ui', 'assets/world']) {
    for (const name of readdirSync(dir).filter((f) => f.endsWith('.model.json'))) {
      walk(JSON.parse(readFileSync(`${dir}/${name}`, 'utf8')), name);
    }
  }
});
test('every image id used by UI models and config comes from an art kit id map', () => {
  const known = new Set();
  for (const kit of readdirSync('assets/source/ui', { withFileTypes: true }).filter((d) => d.isDirectory())) {
    const map = `assets/source/ui/${kit.name}/roblox-ids.json`;
    if (existsSync(map)) Object.values(JSON.parse(readFileSync(map, 'utf8'))).forEach((id) => known.add(id));
  }
  const files = [
    ...readdirSync('assets/ui').filter((f) => f.endsWith('.json')).map((f) => `assets/ui/${f}`),
    'src/shared/Config/UiImages.luau', 'src/first/LoadingImages.luau', 'src/shared/Config/ShopCatalog.luau', 'src/shared/Config/Monetization.luau',
  ];
  for (const file of files) {
    for (const id of readFileSync(file, 'utf8').match(/rbxassetid:\/\/\d+/g) ?? []) {
      assert.ok(known.has(id), `${file} uses ${id}, which no assets/source/ui/*/roblox-ids.json records`);
    }
  }
});
