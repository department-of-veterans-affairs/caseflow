require('babel-polyfill');

let jsdom = require('jsdom').jsdom;

global.document = jsdom('<html><head></head><body><div id="app" /></body></html>');
global.window = document.defaultView;
global.HTMLElement = global.window.HTMLElement;

global.window.performance = {
  now: () => 'RUNNING_IN_NODE'
};

Object.keys(document.defaultView).forEach((property) => {
  if (typeof global[property] === 'undefined') {
    global[property] = document.defaultView[property];
  }
});

global.navigator = {
  userAgent: 'node.js'
};
