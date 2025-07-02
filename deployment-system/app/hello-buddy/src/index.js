const express = require('express');
const app = express();
const port = process.env.PORT || 3000;

app.get('/health', (req, res) => {
    res.status(200).json({ status: 'OK', message: 'Service is up and running' });
});

app.get('/', (req, res) => {
    res.send('Hello Buddy!');
});

// Only start the server if this file is run directly
if (require.main === module) {
    app.listen(port, () => {
        console.log(`Server running on http://localhost:${port}`);
    });
}

// Export the app for testing
module.exports = app;
