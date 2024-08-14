import React from 'react';
// import PropTypes from 'prop-types';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import AppFrame from '../../components/AppFrame';
import { BrowserRouter } from 'react-router-dom';

import SearchableDropdown from '../../components/SearchableDropdown';

export default function LoadTest() {

  return <BrowserRouter>
    <div>
      <AppFrame>
        <AppSegment filledBackground>
          <h1>Test Target Configuration</h1>
          <div>
            <p>Station ID</p>
            <SearchableDropdown
              name="Station id dropdown"
              hideLabel
              // onInputChange={handleInputChange}
              // options={slicedUserOptions} searchable
              // onChange={handleUserSelect}
              // Disable native filter
              filterOption={() => true}
              // value={userSelect}
            />
            <br />
            <p>Regional Office</p>
            <SearchableDropdown
              name="Regional office dropdown"
              hideLabel
              // onInputChange={handleInputChange}
              // options={slicedUserOptions} searchable
              // onChange={handleUserSelect}
              // Disable native filter
              filterOption={() => true}
              // value={userSelect}
            />
          </div>
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
