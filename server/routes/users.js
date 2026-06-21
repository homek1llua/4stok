const express = require('express');
const multer = require('multer');
const path = require('path');
const { v4: uuidv4 } = require('uuid');
const { getDB } = require('../config/db');
const { authMiddleware } = require('../middleware/auth');

const router = express.Router();

const avatarStorage = multer.diskStorage({
  destination: (req, file, cb) => {
    const fs = require('fs');
    const dir = path.join(__dirname, '..', 'uploads', 'avatars');
    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
    cb(null, dir);
  },
  filename: (req, file, cb) => {
    cb(null, uuidv4() + path.extname(file.originalname));
  }
});

const uploadAvatar = multer({ storage: avatarStorage, limits: { fileSize: 5 * 1024 * 1024 } });

router.get('/:id', authMiddleware, (req, res) => {
  try {
    const db = getDB();
    const user = db.prepare('SELECT id, username, display_name, bio, avatar, created_at FROM users WHERE id = ?').get(req.params.id);
    if (!user) return res.status(404).json({ error: 'User not found' });

    const videoCount = db.prepare('SELECT COUNT(*) as count FROM videos WHERE user_id = ?').get(req.params.id).count;
    const followerCount = db.prepare('SELECT COUNT(*) as count FROM follows WHERE following_id = ?').get(req.params.id).count;
    const followingCount = db.prepare('SELECT COUNT(*) as count FROM follows WHERE follower_id = ?').get(req.params.id).count;

    const isFollowing = db.prepare('SELECT id FROM follows WHERE follower_id = ? AND following_id = ?').get(req.userId, req.params.id);

    res.json({
      id: user.id,
      username: user.username,
      displayName: user.display_name,
      bio: user.bio,
      avatar: user.avatar,
      videoCount,
      followerCount,
      followingCount,
      isFollowing: !!isFollowing,
      createdAt: user.created_at
    });
  } catch (err) {
    res.status(500).json({ error: 'Failed to get user' });
  }
});

router.put('/profile', authMiddleware, (req, res) => {
  try {
    const { displayName, bio } = req.body;
    const db = getDB();
    if (displayName) db.prepare('UPDATE users SET display_name = ? WHERE id = ?').run(displayName, req.userId);
    if (bio !== undefined) db.prepare('UPDATE users SET bio = ? WHERE id = ?').run(bio, req.userId);
    const user = db.prepare('SELECT id, username, display_name, bio, avatar FROM users WHERE id = ?').get(req.userId);
    res.json({
      id: user.id,
      username: user.username,
      displayName: user.display_name,
      bio: user.bio,
      avatar: user.avatar
    });
  } catch (err) {
    res.status(500).json({ error: 'Update failed' });
  }
});

router.post('/avatar', authMiddleware, uploadAvatar.single('avatar'), (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ error: 'No file' });
    const db = getDB();
    const filename = '/uploads/avatars/' + req.file.filename;
    db.prepare('UPDATE users SET avatar = ? WHERE id = ?').run(filename, req.userId);
    res.json({ avatar: filename });
  } catch (err) {
    res.status(500).json({ error: 'Avatar upload failed' });
  }
});

router.get('/:id/videos', authMiddleware, (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const offset = (page - 1) * limit;
    const db = getDB();

    const videos = db.prepare(`
      SELECT v.*, u.username, u.display_name, u.avatar
      FROM videos v JOIN users u ON v.user_id = u.id
      WHERE v.user_id = ?
      ORDER BY v.created_at DESC
      LIMIT ? OFFSET ?
    `).all(req.params.id, limit, offset);

    const total = db.prepare('SELECT COUNT(*) as count FROM videos WHERE user_id = ?').get(req.params.id).count;

    res.json({
      videos: videos.map(v => {
        const liked = db.prepare('SELECT id FROM likes WHERE user_id = ? AND video_id = ?').get(req.userId, v.id);
        return {
          id: v.id, caption: v.caption, videoUrl: '/uploads/videos/' + v.filename,
          thumbnail: v.thumbnail ? '/uploads/thumbnails/' + v.thumbnail : null,
          width: v.width, height: v.height, duration: v.duration,
          likesCount: v.likes_count, commentsCount: v.comments_count,
          liked: !!liked, createdAt: v.created_at,
          user: { id: v.user_id, username: v.username, displayName: v.display_name, avatar: v.avatar }
        };
      }),
      page, hasMore: (offset + limit) < total
    });
  } catch (err) {
    res.status(500).json({ error: 'Failed to get user videos' });
  }
});

router.post('/follow/:id', authMiddleware, (req, res) => {
  try {
    if (req.params.id === req.userId) return res.status(400).json({ error: 'Cannot follow yourself' });
    const db = getDB();
    const existing = db.prepare('SELECT id FROM follows WHERE follower_id = ? AND following_id = ?').get(req.userId, req.params.id);
    if (existing) return res.status(400).json({ error: 'Already following' });
    const id = uuidv4();
    const now = new Date().toISOString();
    db.prepare('INSERT INTO follows (id, follower_id, following_id, created_at) VALUES (?, ?, ?, ?)').run(id, req.userId, req.params.id, now);
    res.json({ following: true });
  } catch (err) {
    res.status(500).json({ error: 'Follow failed' });
  }
});

router.post('/unfollow/:id', authMiddleware, (req, res) => {
  try {
    const db = getDB();
    db.prepare('DELETE FROM follows WHERE follower_id = ? AND following_id = ?').run(req.userId, req.params.id);
    res.json({ following: false });
  } catch (err) {
    res.status(500).json({ error: 'Unfollow failed' });
  }
});

router.get('/search/:query', authMiddleware, (req, res) => {
  try {
    const db = getDB();
    const q = `%${req.params.query}%`;
    const users = db.prepare(`
      SELECT id, username, display_name, bio, avatar
      FROM users WHERE username LIKE ? OR display_name LIKE ?
      LIMIT 20
    `).all(q, q);
    res.json(users.map(u => ({
      id: u.id, username: u.username, displayName: u.display_name,
      bio: u.bio, avatar: u.avatar
    })));
  } catch (err) {
    res.status(500).json({ error: 'Search failed' });
  }
});

module.exports = router;
