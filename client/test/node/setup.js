require('babel-polyfill');

// @department-of-veterans-affairs/caseflow-frontend-toolkit has ES6 that we need to compile.
// These tests do not use our normal webpack setup, and instead
// use Mocha's compilation functionality. Normally, mocha does
// not compile anything in node_modules. To get around that, we
// use this module.
import babelNodeModules from 'babel-node-modules';
babelNodeModules(['@department-of-veterans-affairs/caseflow-frontend-toolkit']);

import enzyme from 'enzyme';
import EnzymeAdapterReact16 from 'enzyme-adapter-react-16';

enzyme.configure({ adapter: new EnzymeAdapterReact16() });

let jsdom = require('jsdom').jsdom;

global.document = jsdom('<html><head></head><body><div id="app" /></body></html>');
global.window = document.defaultView;
global.HTMLElement = global.window.HTMLElement;

// eslint-disable-next-line no-empty-function
global.window.analyticsPageView = () => {};
// eslint-disable-next-line no-empty-function
global.window.analyticsEvent = () => {};

global.window.requestIdleCallback = (func) => {
  func();
};

// JSDOM returns undefined for these properties, so we can mock them out globally here.
// Every DOM element will now return 100 for its offsetHeight. We gate it with the if
// statement since when running in watch mode, this definition got called multiple times
// throwing an error.
if (!global.window.HTMLElement.prototype.offsetHeight) {
  Object.defineProperties(global.window.HTMLElement.prototype, {
    offsetHeight: {
      get() {
        return 100;
      }
    }
  });
}

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
