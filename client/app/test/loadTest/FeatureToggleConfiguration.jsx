/* eslint-disable max-lines, max-len */

import React from 'react';
import PropTypes from 'prop-types';

import Checkbox from '../../components/Checkbox';

const FeatureToggleConfiguration = ({ featureToggle, currentState, updateState }) => {
  const handleFeatureToggleSelect = (selectedFeature, value) => {
    const currentFeatureToggles = currentState.user.feature_toggles;
    let featureToggleObjCopy = {};

    if (value) {
      const updatedFeatureToggles = {
        ...currentFeatureToggles,
        [selectedFeature]: value
      };

      featureToggleObjCopy = updatedFeatureToggles;
    } else {
      // eslint-disable-next-line no-unused-vars
      const { [selectedFeature]: removedValue, ...updatedFeatureToggles } = currentFeatureToggles;

      featureToggleObjCopy = updatedFeatureToggles;
    }

    updateState({
      ...currentState,
      user: {
        ...currentState.user,
        feature_toggles: featureToggleObjCopy
      }
    }
    );
  };

  return (
    <div className="load-test-container-checkbox">
      <Checkbox
        label={featureToggle}
        name={featureToggle}
        onChange={(value) => {
          handleFeatureToggleSelect(featureToggle, value);
        }}
        isChecked={Boolean(currentState.user.feature_toggles[featureToggle] ?? false)}
      />
    </div>
  );
};

FeatureToggleConfiguration.propTypes = {
  featureToggle: PropTypes.string,
  currentState: PropTypes.object,
  updateState: PropTypes.func
};

export default FeatureToggleConfiguration;
