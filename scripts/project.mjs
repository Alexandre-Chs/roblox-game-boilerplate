import { spawnSync } from 'node:child_process';
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { homedir } from 'node:os';
import { delimiter, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

process.chdir(fileURLToPath(new URL('../', import.meta.url)));
process.env.PATH = resolve(homedir(), '.rokit/bin') + delimiter + process.env.PATH;
function run(command, args = []) {
  const result = spawnSync(command, args, { stdio: 'inherit', env: process.env });
  if (result.error) throw new Error(`${command}: ${result.error.message}. See README.md prerequisites.`);
  if (result.status !== 0) throw new Error(`${command} failed (${result.status ?? result.signal})`);
}
function sourcemap() {
  run('rojo', ['sourcemap', 'default.project.json', '--output', 'sourcemap.json']);
}
function build() {
  mkdirSync('build', { recursive: true });
  run('rojo', ['build', 'default.project.json', '--output', 'build/starter.rbxlx']);
}
function typecheck() {
  if (!existsSync('globalTypes.d.luau')) throw new Error('Run pnpm run setup first.');
  sourcemap();
  run('luau-lsp', ['analyze', '--definitions=globalTypes.d.luau', '--sourcemap=sourcemap.json', './src']);
}
function test() {
  run(process.execPath, ['--test', 'scripts/project.test.mjs']);
  run('lune', ['run', 'tests/run.luau']);
}
async function publish(target, flags) {
  const places = JSON.parse(readFileSync('places.json', 'utf8'));
  const place = places[target];
  if (!place) throw new Error(`Usage: pnpm run publish <${Object.keys(places).join('|')}>`);
  if (!place.universeId || !place.placeId) throw new Error(`Set universeId and placeId for "${target}" in places.json first.`);
  if (target === 'prod' && !flags.includes('--confirm-prod')) throw new Error('Publishing to prod requires --confirm-prod.');
  const key = process.env.ROBLOX_API_KEY;
  if (!key) throw new Error('Set ROBLOX_API_KEY (Open Cloud key with universe-places write) in your shell.');
  build();
  const url = `https://apis.roblox.com/universes/v1/${place.universeId}/places/${place.placeId}/versions?versionType=Published`;
  const response = await fetch(url, {
    method: 'POST',
    headers: { 'x-api-key': key, 'Content-Type': 'application/xml' },
    body: readFileSync('build/starter.rbxlx'),
    signal: AbortSignal.timeout(120000),
  });
  const text = await response.text();
  if (!response.ok) throw new Error(`Publish failed: HTTP ${response.status} ${text.slice(0, 300)}`);
  console.log(`Published ${target} place ${place.placeId}, version ${JSON.parse(text).versionNumber}.`);
}
const command = process.argv[2];
try {
  switch (command) {
    case 'setup': {
      run('rokit', ['install']);
      const response = await fetch('https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/1.69.0/scripts/globalTypes.d.luau', { signal: AbortSignal.timeout(30000) });
      if (!response.ok) throw new Error(`Roblox types download failed: HTTP ${response.status}`);
      writeFileSync('globalTypes.d.luau', await response.text());
      run('wally', ['install']);
      sourcemap();
      for (const folder of ['Packages/', 'ServerPackages/']) run('wally-package-types', ['--sourcemap', 'sourcemap.json', folder]);
      break;
    }
    case 'setup:art':
      run('python3', ['-m', 'venv', '.venv']);
      run(process.platform === 'win32' ? '.venv/Scripts/python.exe' : '.venv/bin/python', ['-m', 'pip', 'install', '-r', 'requirements-art.lock']);
      break;
    case 'dev': run('rojo', ['serve', 'default.project.json', '--address', '127.0.0.1']); break;
    case 'build': build(); break;
    case 'publish': await publish(process.argv[3], process.argv.slice(4)); break;
    case 'typecheck': typecheck(); break;
    case 'format': run('stylua', ['src', 'tests']); break;
    case 'test': test(); break;
    case 'check':
      run('stylua', ['--check', 'src', 'tests']);
      typecheck();
      test();
      build();
      break;
    case 'doctor':
      for (const tool of ['rokit', 'rojo', 'wally', 'stylua', 'luau-lsp', 'lune', 'python3']) {
        const result = spawnSync(tool, ['--version'], { encoding: 'utf8' });
        console.log(`${tool}: ${result.status === 0 ? result.stdout.trim() : 'MISSING'}`);
      }
      console.log('Studio MCP must be checked from each agent session; CLI availability does not prove connectivity.');
      console.log('Art tools: run .agents/skills/roblox-skills-setup/scripts/check_setup.py (optional).');
      break;
    default: throw new Error(`Unknown command: ${command}`);
  }
} catch (error) {
  console.error(error.message);
  process.exitCode = 1;
}
