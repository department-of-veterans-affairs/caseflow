import enzyme from 'enzyme';
import EnzymeAdapterReact16 from 'enzyme-adapter-react-16';

enzyme.configure({ adapter: new EnzymeAdapterReact16() });

let jsdom = require('jsdom').jsdom;

global.document = jsdom('<html><head></head><body><div id="app" /></body></html>');
global.window = document.defaultView;
global.HTMLElement = global.window.HTMLElement;
global.Element = global.window.Element;

// eslint-disable-next-line no-empty-function
global.window.analyticsPageView = () => {};
// eslint-disable-next-line no-empty-function
global.window.analyticsEvent = () => {};

global.window.requestIdleCallback = (func) => {
  func();
};

global.window.performance.now = jest.fn().mockReturnValue('RUNNING_IN_NODE');

Object.keys(document.defaultView).forEach((property) => {
  if (typeof global[property] === 'undefined') {
    global[property] = document.defaultView[property];
  }
});

global.navigator = {
  userAgent: 'node.js'
};

global.scrollTo = jest.fn();
