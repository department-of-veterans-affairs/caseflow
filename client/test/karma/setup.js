import enzyme from 'enzyme';
import EnzymeAdapterReact16 from 'enzyme-adapter-react-16';

enzyme.configure({ adapter: new EnzymeAdapterReact16() });

// eslint-disable-next-line no-empty-function
window.analyticsPageView = function() {
};

// eslint-disable-next-line no-empty-function
window.analyticsEvent = function() {
};

// eslint-disable-next-line no-empty-function
window.analyticsTiming = function() {
};

