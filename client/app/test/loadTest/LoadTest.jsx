/* eslint-disable max-lines, max-len */

import React, { useState } from 'react';
import LoadTestForm from './LoadTestForm';

export default function LoadTest(props) {
  const [state, setUpdatedState] = useState({});

  return <div>
    <LoadTestForm {...props} currentState={state} updateState={setUpdatedState} />
  </div>;
}
