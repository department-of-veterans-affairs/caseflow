// require all modules ending in "-test" from the 
// current directory and all subdirectories 
var testsContext = require.context(".", true, /-test.js$/);
testsContext.keys().forEach(testsContext);
