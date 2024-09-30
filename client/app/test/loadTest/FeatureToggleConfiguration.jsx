/* eslint-disable max-lines, max-len */

import React, { useState } from 'react';
import PropTypes from 'prop-types';

import Checkbox from '../../components/Checkbox';

export default function FeatureToggleConfiguration(props) {
  const [isChecked, featureIsChecked] = useState(false);

  let feature = props.featureToggle;

  const onChangeHandle = (value) => {
    featureIsChecked(!isChecked);
    props.updateState(
      {
        ...props.currentState,
        user: {
          ...props.currentState.user,
          user: {
            ...props.currentState.user.user,
            feature_toggles: {
              ...props.currentState.user.user.feature_toggles,
              [feature]: value
            }
          }
        }
      }
    );
  };

  return (
    <div className="load-test-container-checkbox">
      <Checkbox
        label={feature}
        name={feature}
        onChange={(value) => {
          onChangeHandle(value);
        }}
        value={isChecked}
      />
    </div>
  );
}

FeatureToggleConfiguration.propTypes = {
  featureToggle: PropTypes.string,
  currentState: PropTypes.object,
  updateState: PropTypes.func
};
