const express = require('express');
const path = require('path');
const app = express();

const metrics = { requests: 0 };
app.use((req, res, next) => {
  if (req.path !== '/metrics') metrics.requests++;
  next();
});

app.get('/metrics', (req, res) => {
  res.set('Content-Type', 'text/plain; version=0.0.4');
  res.send(`# HELP http_requests_total The total number of HTTP requests\n# TYPE http_requests_total counter\nhttp_requests_total ${metrics.requests}\n`);
});

app.use(express.static(path.join(__dirname, 'build')));
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'build', 'index.html'));
});

const PORT = process.env.PORT || 8080;
app.listen(PORT, () => {
  console.log(`Frontend running on port ${PORT}`);
});