import React from 'react';
// import PropTypes from 'prop-types';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import AppFrame from '../../components/AppFrame';
import { BrowserRouter } from 'react-router-dom';

import UserConfiguration from './UserConfiguration';

export default function LoadTest() {

  return <BrowserRouter>
    <div>
      <AppFrame>
        <AppSegment filledBackground>
          <h1>Test Target Configuration</h1>
          <UserConfiguration />
        </AppSegment>
      </AppFrame>
    </div>
  </BrowserRouter>;
}

// LoadTest.propTypes = {
//   // currentUser: PropTypes.object.isRequired,
//   // veteranRecords: PropTypes.array.isRequired,
//   // userDisplayName: PropTypes.string,
//   // dropdownUrls: PropTypes.array,
// };
