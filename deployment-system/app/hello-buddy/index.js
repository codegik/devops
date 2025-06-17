const express = require('express');
const app = express();
const port = process.env.PORT || 3000;

app.get('/health', (req, res) => {
    res.status(200).json({ status: 'OK', message: 'Service is up and running' });
});

app.get('/', (req, res) => {
    res.send('Hello Buddy!');
});

app.listen(port, () => {
    console.log(`Server running on http://localhost:${port}`);
});