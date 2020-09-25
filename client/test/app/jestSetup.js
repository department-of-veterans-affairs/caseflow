import enzyme from 'enzyme';
import EnzymeAdapterReact16 from 'enzyme-adapter-react-16';
import 'jest-axe/extend-expect';
import '@testing-library/jest-dom';

enzyme.configure({ adapter: new EnzymeAdapterReact16() });

global.window.performance.now = jest.fn().mockReturnValue('RUNNING_IN_NODE');
global.scrollTo = jest.fn();

// Spy to ignore console warnings
jest.spyOn(console, 'warn').mockReturnValue();

// Mock the Date generated for all tests
jest.spyOn(Date, 'now').mockReturnValue('2020-07-06T06:00:00.000-04:00');
