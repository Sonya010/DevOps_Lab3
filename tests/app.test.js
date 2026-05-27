const request = require('supertest');

jest.mock('../db', () => ({
  pool: {
    query: jest.fn(),
    end: jest.fn(),
  },
  config: {
    port: 8000,
    db: {
      user: 'student',
      host: 'localhost',
      database: 'tasktracker',
      password: 'testpassword',
      port: 5432,
    },
  },
}));

const { pool } = require('../db');
const express = require('express');
const routes = require('../routes');

function buildApp() {
  const app = express();
  app.use(express.json());
  app.use(express.urlencoded({ extended: true }));
  app.use('/', routes);
  return app;
}

describe('Tasks endpoints', () => {
  let app;

  beforeEach(() => {
    app = buildApp();
    jest.clearAllMocks();
  });

  describe('GET /tasks', () => {
    test('returns list of tasks as JSON', async () => {
      const mockTasks = [
        { id: 1, title: 'Task One', status: 'pending', created_at: new Date().toISOString() },
        { id: 2, title: 'Task Two', status: 'done', created_at: new Date().toISOString() },
      ];
      pool.query.mockResolvedValueOnce({ rows: mockTasks });

      const res = await request(app)
        .get('/tasks')
        .set('Accept', 'application/json');

      expect(res.status).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);
      expect(res.body).toHaveLength(2);
      expect(res.body[0].title).toBe('Task One');
    });

    test('returns empty array when no tasks exist', async () => {
      pool.query.mockResolvedValueOnce({ rows: [] });

      const res = await request(app)
        .get('/tasks')
        .set('Accept', 'application/json');

      expect(res.status).toBe(200);
      expect(res.body).toEqual([]);
    });

    test('returns 500 on database error', async () => {
      pool.query.mockRejectedValueOnce(new Error('DB error'));

      const res = await request(app)
        .get('/tasks')
        .set('Accept', 'application/json');

      expect(res.status).toBe(500);
      expect(res.body.error).toBe('DB error');
    });
  });

  describe('POST /tasks', () => {
    test('creates a task and returns it as JSON', async () => {
      const newTask = { id: 1, title: 'New Task', status: 'pending', created_at: new Date().toISOString() };
      pool.query.mockResolvedValueOnce({ rows: [newTask] });

      const res = await request(app)
        .post('/tasks')
        .set('Accept', 'application/json')
        .send({ title: 'New Task' });

      expect(res.status).toBe(200);
      expect(res.body.title).toBe('New Task');
      expect(res.body.status).toBe('pending');
    });

    test('returns 400 when title is missing', async () => {
      const res = await request(app)
        .post('/tasks')
        .set('Accept', 'application/json')
        .send({});

      expect(res.status).toBe(400);
    });

    test('returns 500 on database error', async () => {
      pool.query.mockRejectedValueOnce(new Error('Insert failed'));

      const res = await request(app)
        .post('/tasks')
        .set('Accept', 'application/json')
        .send({ title: 'Task with error' });

      expect(res.status).toBe(500);
    });
  });

  describe('POST /tasks/:id/done', () => {
    test('marks a task as done and returns it', async () => {
      const updatedTask = { id: 1, title: 'Task One', status: 'done', created_at: new Date().toISOString() };
      pool.query.mockResolvedValueOnce({ rows: [updatedTask] });

      const res = await request(app)
        .post('/tasks/1/done')
        .set('Accept', 'application/json');

      expect(res.status).toBe(200);
      expect(res.body.status).toBe('done');
    });

    test('returns 404 when task does not exist', async () => {
      pool.query.mockResolvedValueOnce({ rows: [] });

      const res = await request(app)
        .post('/tasks/999/done')
        .set('Accept', 'application/json');

      expect(res.status).toBe(404);
    });

    test('returns 500 on database error', async () => {
      pool.query.mockRejectedValueOnce(new Error('Update failed'));

      const res = await request(app)
        .post('/tasks/1/done')
        .set('Accept', 'application/json');

      expect(res.status).toBe(500);
    });
  });
});
