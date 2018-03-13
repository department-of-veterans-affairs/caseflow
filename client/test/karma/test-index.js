import enzyme from 'enzyme';
import EnzymeAdapterReact16 from 'enzyme-adapter-react-16';

enzyme.configure({ adapter: new EnzymeAdapterReact16() });

import '@department-of-veterans-affairs/caseflow-frontend-toolkit/test-export/bootstrap';

// require all modules ending in "-test" from the
// current directory and all subdirectories
const testsContext = require.context('.', true, /-test.js$/);

testsContext.keys().forEach(testsContext);
