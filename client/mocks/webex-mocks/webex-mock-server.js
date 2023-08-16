const jsonServer = require("json-server");
const express = require("express");
const server = jsonServer.create();
const router = jsonServer.router("mocks/webex-mocks/webex-mock.json"); // your mock data file
const middlewares = jsonServer.defaults();

server.use(middlewares);
server.use(jsonServer.bodyParser);

// Example custom routes for specific error handling
server.get("/error-400", (req, res) => {
  res
    .status(400)
    .json({
      message: "The request was invalid or cannot be otherwise served.",
    });
});

server.get("/error-401", (req, res) => {
  res
    .status(401)
    .json({ message: "Authentication credentials were missing or incorrect." });
});

// ... Similarly, add routes for other error codes ...

// Middleware to handle not-found items
server.use((req, res, next) => {
  if (req.method === 'GET' && res.locals.data == null) {
    res.status(404).json({ message: "Item not found" });
  } else {
    next();
  }
});

// To handle the default behavior, use the router middleware last
server.use(router);

// Start the server
server.listen(3001, () => {
  console.log("JSON Server is running on port 3001");
});
