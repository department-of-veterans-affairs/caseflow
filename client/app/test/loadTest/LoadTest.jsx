import React, { useState } from 'react';
import LoadTestForm from './LoadTestForm';
import PropTypes from 'prop-types';

export default function LoadTest(props) {
  const currentFeatures = {};

  props.form_values.feature_toggles_available.forEach((feature) => {
    currentFeatures[feature.name] = feature.default_status;
  });

  const [state, setUpdatedState] = useState(
    {
      scenarios: [],
      user: {
        station_id: '',
        regional_office: '',
        roles: [],
        functions: {},
        organizations: [],
        feature_toggles: currentFeatures
      }
    }
  );

  return <div>
    <LoadTestForm {...props} currentState={state} updateState={setUpdatedState} />
  </div>;
}

LoadTest.propTypes = {
  form_values: PropTypes.object
};

/*
This file acts as a container to the LoadTestForm. Consider this a note on what the overall behavior of this
portion of the app is.

The component tree is as follows:
    -LoadTestForm // the actual form for the load test. The onSubmit happens here when the button is clicked.
      the body of the POST request is set up here as well through the use of the currentState method.
        -UserConfiguration and Scenario Configurations are rendered through the LoadTestForm. Both making
          use of the updateState and currentState methods.

State is created in this file and then passed in to the rendered component,
  both the getter and setter methods that will provide updates to state as
  the changes are made in the form. As selections happen, state wil be updated providing an 'easy'
  way to create the body for the POST request.
*/
