const jsonServer = require('json-server');
const server = jsonServer.create();
const path = require('path');
const router = jsonServer.router(
  path.join('mocks/webex-mocks/webex-mock.json')
);
const middlewares = jsonServer.defaults();
const routesRewrite = require('./routes.json');

server.use(middlewares);
server.use(jsonServer.bodyParser);

// Apply the routes rewrites
server.use(jsonServer.rewriter(routesRewrite));

// Custom error routes and handlers
server.get('/error-400', (req, res) => {
  res.status(400).json({
    message: 'The request was invalid or cannot be otherwise served.',
  });
});

server.get('/error-401', (req, res) => {
  res.status(401).json({
    message: 'Authentication credentials were missing or incorrect.',
  });
});

server.get('/error-403', (req, res) => {
  res.status(403).json({
    message:
      'The request is understood, but it has been refused or access is not allowed',
  });
});

server.get('/error-405', (req, res) => {
  res.status(405).json({
    message:
      'The request was made to a resource using an HTTP request method that is not supported.',
  });
});

server.get('/error-409', (req, res) => {
  res.status(409).json({
    message:
      'The request could not be processed because it conflicts with some established rule of the system.',
  });
});

server.get('/error-410', (req, res) => {
  res.status(410).json({
    message: 'The requested resource is no longer available.',
  });
});

server.get('/error-415', (req, res) => {
  res.status(415).json({
    message:
      'The request was made to a resource without specifying a media type or used a media type that is not supported.',
  });
});

server.get('/error-423', (req, res) => {
  res.status(423).json({
    message: 'The requested resource is temporarily unavailable',
  });
});

server.get('/error-428', (req, res) => {
  res.status(428).json({
    message:
      'File(s) cannot be scanned for malware and need to be force downloaded.',
  });
});

server.get('/error-429', (req, res) => {
  res.status(429).json({
    message:
      'Too many requests have been sent in a given amount of time and the request has been rate limited.',
  });
});

server.get('/error-500', (req, res) => {
  res.status(500).json({
    message: 'Something went wrong on the server.',
  });
});

server.get('/error-502', (req, res) => {
  res.status(502).json({
    message:
      'The server received an invalid response from an upstream server while processing the request.',
  });
});

server.get('/error-503', (req, res) => {
  res.status(503).json({
    message: 'Server is overloaded with requests. Try again later.',
  });
});

server.get('/error-504', (req, res) => {
  res.status(504).json({
    message:
      'An upstream server failed to respond on time. If your query uses max parameter, please try to reduce it.',
  });
});

server.get('/health-check-yellow', (req, res) => {
  res.status(200).json({
    status: 'yellow',
  });
});

server.get('/health-check-red', (req, res) => {
  res.status(200).json({
    status: 'red',
  });
});

server.get('/health-check-green', (req, res) => {
  res.status(200).json({
    status: 'green',
  });
});

// Middleware to handle duplication and not-found items
server.use((req, res, next) => {
  const db = router.db; // Get the lowdb instance

  // Handle POST requests: Check for duplicate items by ID across all collections
  if (req.method === 'POST') {
    const collections = Object.keys(db.getState());

    for (const collectionName of collections) {
      const collection = db.get(collectionName);
      const existingItem = collection.find({ id: req.body.id }).value();

      if (existingItem) {
        res.status(409).json({
          error: true,
          message: `Item with the same id already exists in ${collectionName}`
        });

        return;
      }
    }
  }

  // Handle GET requests: Check if the item exists across all collections
  if (req.method === 'GET') {
    // Extract the id from the path. This assumes the path format is always consistent.
    const pathParts = req.path.split('/');
    const potentialId = parseInt(pathParts.pop());

    if (!isNaN(potentialId)) {
      const collections = Object.keys(db.getState());
      let itemFound = false;

      for (const collectionName of collections) {
        const collection = db.get(collectionName);
        const item = collection.find({ id: potentialId }).value();

        if (item) {
          itemFound = true;
          break;
        }
      }

      if (!itemFound) {
        res.status(404).json({
          error: true,
          message: 'Item not found'
        });

        return;
      }
    }
  }

  next();
});

server.use(router);

const errorRoutes = [
  '/error-400',
  '/error-401',
  '/error-403',
  '/error-404',
  '/error-405',
  '/error-409',
  '/error-410',
  '/error-415',
  '/error-423',
  '/error-428',
  '/error-429',
  '/error-500',
  '/error-502',
  '/error-503',
  '/error-504',
  '/health-check-yellow',
  '/health-check-red',
  '/health-check-green',
];

server.listen(3050, () => {
  console.log(' \\{^_^}/ hi!\n');
  console.log(' Loading mocks/webex-mocks/webex-mock.json');
  console.log(' Done\n');

  console.log( ' Resources:');

  // Original routes from the database state
  const originalRoutes = Object.keys(router.db.getState());

  // Rewritten routes based on the routes.json rewrites
  const rewrittenRoutes = originalRoutes.map((route) => {
    for (let key in routesRewrite) {
      if (routesRewrite[key] === `/${route}`) {
        return key; // returning the custom path
      }
    }
    return `/${route}`; // returning the original path if no custom path found
  });

  rewrittenRoutes.forEach((route) => {
    console.log(` http://localhost:3050${route}`);
  });

  console.log('\n Error Routes:');
  errorRoutes.forEach((route) => {
    console.log(` ${route}`);
  });

  console.log('\n Home');
  console.log(' http://localhost:3050');

  console.log(
    '\n Type s + enter at any time to create a snapshot of the database'
  );
  console.log( 'Watching...');
});
