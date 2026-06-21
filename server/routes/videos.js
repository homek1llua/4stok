const express = require('express');
const multer = require('multer');
const path = require('path');
const { v4: uuidv4 } = require('uuid');
const { getDB } = require('../config/db');
const { authMiddleware } = require('../middleware/auth');

const router = express.Router();

const videoStorage = multer.diskStorage({
  destination: (req, file, cb) => {
    const fs = require('fs');
    const dir = path.join(__dirname, '..', 'uploads', 'videos');
    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
    cb(null, dir);
  },
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname) || '.mp4';
    cb(null, uuidv4() + ext);
  }
});

const thumbnailStorage = multer.diskStorage({
  destination: (req, file, cb) => {
    const fs = require('fs');
    const dir = path.join(__dirname, '..', 'uploads', 'thumbnails');
    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
    cb(null, dir);
  },
  filename: (req, file, cb) => {
    cb(null, uuidv4() + '.jpg');
  }
});

const uploadVideo = multer({
  storage: videoStorage,
  limits: { fileSize: 100 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    const allowed = ['.mp4', '.mov', '.avi', '.m4v'];
    const ext = path.extname(file.originalname).toLowerCase();
    if (allowed.includes(ext)) cb(null, true);
    else cb(new Error('Invalid video format'));
  }
});

const uploadThumb = multer({
  storage: thumbnailStorage,
  limits: { fileSize: 5 * 1024 * 1024 }
});

router.post('/upload', authMiddleware, uploadVideo.single('video'), (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ error: 'No video file' });
    const { caption } = req.body;
    const id = uuidv4();
    const db = getDB();

    const now = new Date().toISOString();
    db.prepare(
      'INSERT INTO videos (id, user_id, caption, filename, created_at) VALUES (?, ?, ?, ?, ?)'
    ).run(id, req.userId, caption || '', req.file.filename, now);

    const video = db.prepare(`
      SELECT v.*, u.username, u.display_name, u.avatar
      FROM videos v JOIN users u ON v.user_id = u.id
      WHERE v.id = ?
    `).get(id);

    res.status(201).json(formatVideo(video, req.userId));
  } catch (err) {
    console.error('Upload error:', err);
    res.status(500).json({ error: 'Upload failed' });
  }
});

router.post('/upload-thumbnail', authMiddleware, uploadThumb.single('thumbnail'), (req, res) => {
  try {
    if (!req.file || !req.body.videoId) {
      return res.status(400).json({ error: 'Missing thumbnail or videoId' });
    }
    const db = getDB();
    db.prepare('UPDATE videos SET thumbnail = ? WHERE id = ? AND user_id = ?')
      .run(req.file.filename, req.body.videoId, req.userId);
    res.json({ thumbnail: req.file.filename });
  } catch (err) {
    res.status(500).json({ error: 'Thumbnail upload failed' });
  }
});

router.get('/feed', authMiddleware, (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const offset = (page - 1) * limit;

    const db = getDB();
    const videos = db.prepare(`
      SELECT v.*, u.username, u.display_name, u.avatar
      FROM videos v
      JOIN users u ON v.user_id = u.id
      ORDER BY v.created_at DESC
      LIMIT ? OFFSET ?
    `).all(limit, offset);

    const total = db.prepare('SELECT COUNT(*) as count FROM videos').get().count;

    const userId = req.userId;
    const feed = videos.map(v => formatVideo(v, userId));

    res.json({
      videos: feed,
      page,
      hasMore: (offset + limit) < total
    });
  } catch (err) {
    console.error('Feed error:', err);
    res.status(500).json({ error: 'Failed to load feed' });
  }
});

router.get('/:id', authMiddleware, (req, res) => {
  try {
    const db = getDB();
    const video = db.prepare(`
      SELECT v.*, u.username, u.display_name, u.avatar
      FROM videos v JOIN users u ON v.user_id = u.id
      WHERE v.id = ?
    `).get(req.params.id);

    if (!video) return res.status(404).json({ error: 'Video not found' });
    res.json(formatVideo(video, req.userId));
  } catch (err) {
    res.status(500).json({ error: 'Failed to get video' });
  }
});

router.delete('/:id', authMiddleware, (req, res) => {
  try {
    const db = getDB();
    const video = db.prepare('SELECT * FROM videos WHERE id = ? AND user_id = ?').get(req.params.id, req.userId);
    if (!video) return res.status(404).json({ error: 'Video not found or not yours' });

    const fs = require('fs');
    const videoPath = path.join(__dirname, '..', 'uploads', 'videos', video.filename);
    if (fs.existsSync(videoPath)) fs.unlinkSync(videoPath);
    if (video.thumbnail) {
      const thumbPath = path.join(__dirname, '..', 'uploads', 'thumbnails', video.thumbnail);
      if (fs.existsSync(thumbPath)) fs.unlinkSync(thumbPath);
    }

    db.prepare('DELETE FROM likes WHERE video_id = ?').run(req.params.id);
    db.prepare('DELETE FROM comments WHERE video_id = ?').run(req.params.id);
    db.prepare('DELETE FROM videos WHERE id = ?').run(req.params.id);

    res.json({ message: 'Deleted' });
  } catch (err) {
    res.status(500).json({ error: 'Delete failed' });
  }
});

router.post('/:id/like', authMiddleware, (req, res) => {
  try {
    const db = getDB();
    const existing = db.prepare('SELECT id FROM likes WHERE user_id = ? AND video_id = ?').get(req.userId, req.params.id);
    if (existing) {
      return res.status(400).json({ error: 'Already liked' });
    }
    const id = uuidv4();
    const now = new Date().toISOString();
    db.prepare('INSERT INTO likes (id, user_id, video_id, created_at) VALUES (?, ?, ?, ?)').run(id, req.userId, req.params.id, now);
    db.prepare('UPDATE videos SET likes_count = likes_count + 1 WHERE id = ?').run(req.params.id);
    const video = db.prepare('SELECT likes_count FROM videos WHERE id = ?').get(req.params.id);
    res.json({ liked: true, likesCount: video.likes_count });
  } catch (err) {
    res.status(500).json({ error: 'Like failed' });
  }
});

router.post('/:id/unlike', authMiddleware, (req, res) => {
  try {
    const db = getDB();
    const existing = db.prepare('SELECT id FROM likes WHERE user_id = ? AND video_id = ?').get(req.userId, req.params.id);
    if (!existing) {
      return res.status(400).json({ error: 'Not liked yet' });
    }
    db.prepare('DELETE FROM likes WHERE user_id = ? AND video_id = ?').run(req.userId, req.params.id);
    db.prepare('UPDATE videos SET likes_count = MAX(0, likes_count - 1) WHERE id = ?').run(req.params.id);
    const video = db.prepare('SELECT likes_count FROM videos WHERE id = ?').get(req.params.id);
    res.json({ liked: false, likesCount: video.likes_count });
  } catch (err) {
    res.status(500).json({ error: 'Unlike failed' });
  }
});

router.get('/:id/comments', authMiddleware, (req, res) => {
  try {
    const db = getDB();
    const comments = db.prepare(`
      SELECT c.id, c.text, c.created_at,
             u.id as user_id, u.username, u.display_name, u.avatar
      FROM comments c
      JOIN users u ON c.user_id = u.id
      WHERE c.video_id = ?
      ORDER BY c.created_at DESC
      LIMIT 50
    `).all(req.params.id);

    res.json(comments.map(c => ({
      id: c.id,
      text: c.text,
      createdAt: c.created_at,
      user: {
        id: c.user_id,
        username: c.username,
        displayName: c.display_name,
        avatar: c.avatar
      }
    })));
  } catch (err) {
    res.status(500).json({ error: 'Failed to load comments' });
  }
});

router.post('/:id/comments', authMiddleware, (req, res) => {
  try {
    const { text } = req.body;
    if (!text || !text.trim()) return res.status(400).json({ error: 'Comment text required' });

    const db = getDB();
    const id = uuidv4();
    const videoExists = db.prepare('SELECT id FROM videos WHERE id = ?').get(req.params.id);
    if (!videoExists) return res.status(404).json({ error: 'Video not found' });

    const now = new Date().toISOString();
    db.prepare('INSERT INTO comments (id, user_id, video_id, text, created_at) VALUES (?, ?, ?, ?, ?)').run(id, req.userId, req.params.id, text, now);
    db.prepare('UPDATE videos SET comments_count = comments_count + 1 WHERE id = ?').run(req.params.id);

    const comment = db.prepare(`
      SELECT c.id, c.text, c.created_at,
             u.id as user_id, u.username, u.display_name, u.avatar
      FROM comments c
      JOIN users u ON c.user_id = u.id
      WHERE c.id = ?
    `).get(id);

    res.status(201).json({
      id: comment.id,
      text: comment.text,
      createdAt: comment.created_at,
      user: {
        id: comment.user_id,
        username: comment.username,
        displayName: comment.display_name,
        avatar: comment.avatar
      }
    });
  } catch (err) {
    res.status(500).json({ error: 'Comment failed' });
  }
});

function formatVideo(v, currentUserId) {
  const db = getDB();
  const liked = db.prepare('SELECT id FROM likes WHERE user_id = ? AND video_id = ?').get(currentUserId, v.id);
  return {
    id: v.id,
    caption: v.caption,
    videoUrl: '/uploads/videos/' + v.filename,
    thumbnail: v.thumbnail ? '/uploads/thumbnails/' + v.thumbnail : null,
    width: v.width,
    height: v.height,
    duration: v.duration,
    likesCount: v.likes_count,
    commentsCount: v.comments_count,
    liked: !!liked,
    createdAt: v.created_at,
    user: {
      id: v.user_id,
      username: v.username,
      displayName: v.display_name,
      avatar: v.avatar
    }
  };
}

module.exports = router;
