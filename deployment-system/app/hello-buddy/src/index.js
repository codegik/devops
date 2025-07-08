const express = require('express');
const promClient = require('prom-client');
const app = express();
const port = process.env.PORT || 3000;

// Initialize Prometheus metrics collection
const register = new promClient.Registry();
promClient.collectDefaultMetrics({ register });

// Create custom metrics
const httpRequestCounter = new promClient.Counter({
  name: 'hello_buddy_http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'endpoint', 'status'],
  registers: [register]
});

const httpRequestDuration = new promClient.Histogram({
  name: 'hello_buddy_http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'endpoint', 'status'],
  buckets: [0.01, 0.05, 0.1, 0.5, 1, 2, 5],
  registers: [register]
});

// Middleware to track HTTP request metrics
app.use((req, res, next) => {
  const start = Date.now();

  // Record the request
  res.on('finish', () => {
    const duration = (Date.now() - start) / 1000; // Convert to seconds
    httpRequestCounter.inc({
      method: req.method,
      endpoint: req.path,
      status: res.statusCode
    });
    httpRequestDuration.observe(
      { method: req.method, endpoint: req.path, status: res.statusCode },
      duration
    );
  });

  next();
});

// Expose metrics endpoint for Prometheus
app.get('/metrics', async (req, res) => {
  try {
    res.set('Content-Type', register.contentType);
    const metrics = await register.metrics();
    res.end(metrics);
    console.log('Metrics endpoint accessed');
  } catch (err) {
    console.error('Error generating metrics:', err);
    res.status(500).end();
  }
});

app.get('/health', (req, res) => {
  const buildNumber = process.env.BUILD_NUMBER || 'dev';
  res.status(200).json({
    status: 'OK',
    message: 'Service is up and running',
    buildNumber: buildNumber
  });
});

app.get('/', (req, res) => {
  res.send('Hello Buddy!');
});

// Only start the server if this file is run directly
if (require.main === module) {
  app.listen(port, () => {
    console.log(`Server running on http://localhost:${port}`);
    console.log(`Metrics available at http://localhost:${port}/metrics`);
  });
}

module.exports = app;
