import enzyme from 'enzyme';
import EnzymeAdapterReact16 from 'enzyme-adapter-react-16';

enzyme.configure({ adapter: new EnzymeAdapterReact16() });

global.window.performance.now = jest.fn().mockReturnValue('RUNNING_IN_NODE');
global.scrollTo = jest.fn();

// Spy to ignore console warnings
jest.spyOn(console, 'warn').mockReturnValue();
