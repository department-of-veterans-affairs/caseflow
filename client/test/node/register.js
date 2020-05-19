const path = require('path');

const rootPath = path.join(__dirname, '..', '..');

require('@babel/register')({
  root: rootPath,
  ignore: [
    /node_modules\/((?!(.*caseflow-frontend-toolkit)).*)[\\/]?/
  ]
});
