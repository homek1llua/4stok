const initSqlJs = require('sql.js');
const fs = require('fs');
const path = require('path');

const DB_PATH = path.join(__dirname, '..', 'data', 'tiktok.db');
const dir = path.dirname(DB_PATH);
if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });

let db = null;
let initPromise = null;

async function initDB() {
  if (initPromise) return initPromise;
  initPromise = (async () => {
    const SQL = await initSqlJs();
    try {
      const buf = fs.readFileSync(DB_PATH);
      db = new SQL.Database(buf);
    } catch (e) {
      db = new SQL.Database();
    }

    db.run('PRAGMA foreign_keys = ON');
    db.run("CREATE TABLE IF NOT EXISTS users (id TEXT PRIMARY KEY, username TEXT UNIQUE NOT NULL, display_name TEXT NOT NULL, password TEXT NOT NULL, bio TEXT DEFAULT '', avatar TEXT DEFAULT '', created_at TEXT DEFAULT (''))");
    db.run("CREATE TABLE IF NOT EXISTS videos (id TEXT PRIMARY KEY, user_id TEXT NOT NULL, caption TEXT DEFAULT '', filename TEXT NOT NULL, thumbnail TEXT DEFAULT '', width INTEGER DEFAULT 480, height INTEGER DEFAULT 854, duration REAL DEFAULT 0, likes_count INTEGER DEFAULT 0, comments_count INTEGER DEFAULT 0, created_at TEXT DEFAULT (''), FOREIGN KEY (user_id) REFERENCES users(id))");
    db.run("CREATE TABLE IF NOT EXISTS likes (id TEXT PRIMARY KEY, user_id TEXT NOT NULL, video_id TEXT NOT NULL, created_at TEXT DEFAULT (''), FOREIGN KEY (user_id) REFERENCES users(id), FOREIGN KEY (video_id) REFERENCES videos(id), UNIQUE(user_id, video_id))");
    db.run("CREATE TABLE IF NOT EXISTS comments (id TEXT PRIMARY KEY, user_id TEXT NOT NULL, video_id TEXT NOT NULL, text TEXT NOT NULL, created_at TEXT DEFAULT (''), FOREIGN KEY (user_id) REFERENCES users(id), FOREIGN KEY (video_id) REFERENCES videos(id))");
    db.run("CREATE TABLE IF NOT EXISTS follows (id TEXT PRIMARY KEY, follower_id TEXT NOT NULL, following_id TEXT NOT NULL, created_at TEXT DEFAULT (''), FOREIGN KEY (follower_id) REFERENCES users(id), FOREIGN KEY (following_id) REFERENCES users(id), UNIQUE(follower_id, following_id))");
    saveDB();

    // Proxy to mimic better-sqlite3 API
    const origDb = db;
    db = new Proxy(origDb, {
      get(target, prop) {
        if (prop === 'prepare') {
          return (sql) => {
            const stmt = target.prepare(sql);
            return {
              run: (...params) => { stmt.bind(params); stmt.step(); stmt.free(); saveDB(); },
              get: (...params) => { stmt.bind(params); if (stmt.step()) { const r = stmt.getAsObject(); stmt.free(); return r; } stmt.free(); return undefined; },
              all: (...params) => { stmt.bind(params); const results = []; while (stmt.step()) results.push(stmt.getAsObject()); stmt.free(); return results; }
            };
          };
        }
        return target[prop];
      }
    });
  })();
  return initPromise;
}

function getDB() {
  return db;
}

function saveDB() {
  try {
    fs.writeFileSync(DB_PATH, Buffer.from(db.export()));
  } catch (e) {
    console.error('Save DB error:', e.message);
  }
}

module.exports = { getDB, initDB, saveDB };
