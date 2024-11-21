import React, { useState } from 'react';
import PropTypes from 'prop-types';

import Checkbox from '../../components/Checkbox';

const FeatureToggleConfiguration = ({ featureToggle, currentState, updateState }) => {
  const [checked, setChecked] = useState(featureToggle.default_status);

  const handleFeatureToggleSelect = (selectedFeature, value) => {
    const currentFeatureToggles = currentState.user.feature_toggles;

    setChecked(!checked);

    currentFeatureToggles[selectedFeature] = value;

    updateState({
      ...currentState,
      user: {
        ...currentState.user,
        feature_toggles: currentFeatureToggles
      }
    }
    );
  };

  return (
    <div className="load-test-container-checkbox">
      <Checkbox
        label={featureToggle.name}
        name={featureToggle.name}
        onChange={(value) => {
          handleFeatureToggleSelect(featureToggle.name, value);
        }}
        isChecked={checked}
        defaultValue={featureToggle.default_status}
      />
    </div>
  );
};

FeatureToggleConfiguration.propTypes = {
  featureToggle: PropTypes.object,
  currentState: PropTypes.object,
  updateState: PropTypes.func
};

export default FeatureToggleConfiguration;
