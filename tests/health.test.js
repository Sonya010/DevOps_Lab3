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
  app.get('/', (req, res) => {
    res.setHeader('Content-Type', 'text/html');
    res.send('<h1>mywebapp - Task Tracker</h1>');
  });
  app.use('/', routes);
  return app;
}

describe('Health endpoints', () => {
  let app;

  beforeEach(() => {
    app = buildApp();
    jest.clearAllMocks();
  });

  test('GET /health/alive returns 200 OK', async () => {
    const res = await request(app).get('/health/alive');
    expect(res.status).toBe(200);
    expect(res.text).toBe('OK');
  });

  test('GET /health/ready returns 200 when DB is reachable', async () => {
    pool.query.mockResolvedValueOnce({ rows: [] });
    const res = await request(app).get('/health/ready');
    expect(res.status).toBe(200);
    expect(res.text).toBe('OK');
  });

  test('GET /health/ready returns 500 when DB is unreachable', async () => {
    pool.query.mockRejectedValueOnce(new Error('Connection refused'));
    const res = await request(app).get('/health/ready');
    expect(res.status).toBe(500);
    expect(res.text).toContain('Database connection error');
  });
});

describe('Main route', () => {
  let app;

  beforeEach(() => {
    app = buildApp();
  });

  test('GET / returns HTML with task tracker info', async () => {
    const res = await request(app).get('/');
    expect(res.status).toBe(200);
    expect(res.headers['content-type']).toMatch(/html/);
    expect(res.text).toContain('Task Tracker');
  });
});
