// require all modules ending in "-test" from the
// current directory and all subdirectories
const testsContext = require.context('.', true, /-test.js$/);

testsContext.keys().forEach(testsContext);
