/* eslint-disable max-lines, max-len */

import React, { useState } from 'react';
import LoadTestForm from './LoadTestForm';

export default function LoadTest(props) {
  const [state, setUpdatedState] = useState(
    {
      scenarios: [],
      user: {
        user: {
          station_id: '',
          regional_office: '',
          roles: [],
          functions: {},
          organizations: [],
          feature_toggles: {}
        }
      }
    }
  );

  return <div>
    <LoadTestForm {...props} currentState={state} updateState={setUpdatedState} />
  </div>;
}
