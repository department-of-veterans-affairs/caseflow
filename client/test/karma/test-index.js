// require all modules ending in "-test" from the
// current directory and all subdirectories
const Adapter = require('enzyme-adapter-react-15');
const Enzyme = require('enzyme');

Enzyme.configure({ adapter: new Adapter() });

const testsContext = require.context('.', true, /-test.js$/);

testsContext.keys().forEach(testsContext);
