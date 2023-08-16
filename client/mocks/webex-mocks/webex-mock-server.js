const jsonServer = require('json-server');
const server = jsonServer.create();
const router = jsonServer.router('mocks/webex-mocks/webex-mock.json');
const middlewares = jsonServer.defaults();

server.use(middlewares);
server.use(jsonServer.bodyParser);

// Example custom routes for specific error handling
server.get('/error-400', (req, res) => {
  res.status(400).json({
    message: 'The request was invalid or cannot be otherwise served.',
  });
});

server.get('/error-401', (req, res) => {
  res.status(401).json({
    message: 'Authentication credentials were missing or incorrect.'
  });
});

server.get('/error-403', (req, res) => {
  res.status(403).json({
    message: 'The request is understood, but it has been refused or access is not allowed',
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

// ... Similarly, add routes for other error codes ...

// To handle the default behavior, use the router middleware last
server.use(router);

// Middleware to handle not-found items
server.use((req, res, next) => {
  if (req.method === 'GET' && res.locals.data === null) {
    res.status(404).json({ message: 'Item not found' });
  } else {
    next();
  }
});

const errorRoutes = [
  {
    path: '/error-400',
    description: 'The request was invalid or cannot be otherwise served.'
  },
  {
    path: '/error-401',
    description: 'Authentication credentials were missing or incorrect.'
  }
  // ... Add other error routes here
];

// ...

server.listen(3050, () => {
  console.log(' \\{^_^}/ hi!\n');
  console.log(' Loading mocks/webex-mocks/webex-mock.json');
  console.log(' Done\n');

  console.log(' Resources:');
  const routes = Object.keys(router.db.getState());

  routes.forEach((route) => {
    console.log(` http://localhost:3050/${route}`);
  });

  console.log('\n Error Routes:');
  errorRoutes.forEach(route => {
    console.log(` ${route.path} - ${route.description}`);
  });

  console.log('\n Home');
  console.log(' http://localhost:3050');

  console.log('\n Type s + enter at any time to create a snapshot of the database');
  console.log(' Watching...');
});
