const fs = require('fs');
const path = require('path');

const GAMES_DIR = path.join(__dirname, '..', 'games');
const GAMES_LUA_PATH = path.join(__dirname, '..', 'games.lua');
const SCRIPT_BASE_URL = process.env.SCRIPT_BASE_URL || 'https://raw.githubusercontent.com/LKHUB-dev/Lua/refs/heads/main/';

function parseGameFile(filePath) {
  const content = fs.readFileSync(filePath, 'utf8');
  const placeIdMatch = content.match(/^--\s*PlaceId:\s*(\d+)/m);
  if (!placeIdMatch) return null;
  const placeId = placeIdMatch[1];
  const scriptPathMatch = content.match(/^--\s*ScriptPath:\s*(.+)/m);
  const scriptPath = scriptPathMatch ? scriptPathMatch[1].trim() : null;
  const nameMatch = content.match(/^--\s*GameName:\s*(.+)/m);
  const gameNameOverride = nameMatch ? nameMatch[1].trim() : null;
  const basename = path.basename(filePath, '.lua');
  return { placeId, scriptPath: scriptPath || `scripts/${basename}.lua`, gameNameOverride };
}

async function getUniverseId(placeId) {
  const res = await fetch(`https://apis.roblox.com/universes/v1/places/${placeId}/universe`);
  if (!res.ok) throw new Error(`place ${placeId}: ${res.status}`);
  const data = await res.json();
  return String(data.universeId);
}

async function getGameInfo(universeId) {
  const res = await fetch(`https://games.roblox.com/v1/games?universeIds=${universeId}`);
  if (!res.ok) throw new Error(`universe ${universeId}: ${res.status}`);
  const data = await res.json();
  const game = data.data && data.data[0];
  if (!game) throw new Error(`no game for universe ${universeId}`);
  return { name: game.name || 'Unknown', rootPlaceId: game.rootPlaceId };
}

function escapeLuaString(s) {
  return '"' + String(s).replace(/\\/g, '\\\\').replace(/"/g, '\\"').replace(/\n/g, '\\n') + '"';
}

async function main() {
  const files = fs.readdirSync(GAMES_DIR).filter(f => f.endsWith('.lua'));
  const entries = [];
  for (const file of files) {
    const parsed = parseGameFile(path.join(GAMES_DIR, file));
    if (!parsed) continue;
    const gameId = await getUniverseId(parsed.placeId);
    const info = await getGameInfo(gameId);
    const gameName = parsed.gameNameOverride || info.name;
    const scriptUrl = (SCRIPT_BASE_URL.replace(/\/$/, '') + '/' + parsed.scriptPath.replace(/^\//, ''));
    entries.push({ gameId, gameName, placeIds: [parsed.placeId], scriptUrl });
  }
  const lua = `return {\n${entries.map(e =>
    `\t[${escapeLuaString(e.gameId)}] = {\n\t\tgameName = ${escapeLuaString(e.gameName)},\n\t\tplaceIds = { ${e.placeIds.join(', ')} },\n\t\tscriptUrl = ${escapeLuaString(e.scriptUrl)}\n\t}`
  ).join(',\n')}\n}\n`;
  fs.writeFileSync(GAMES_LUA_PATH, lua, 'utf8');
  console.log('games.lua updated:', entries.length, 'games');
}

main().catch(err => { console.error(err); process.exit(1); });
