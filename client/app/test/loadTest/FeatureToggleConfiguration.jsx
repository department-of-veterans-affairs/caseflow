/* eslint-disable max-lines, max-len */

import React, { useState } from 'react';
import PropTypes from 'prop-types';

import Checkbox from '../../components/Checkbox';

export default function FeatureToggleConfiguration(props) {
  // const [isChecked, featureIsChecked] = useState(false);
  // eslint-disable-next-line no-unused-vars
  const [selectedFeatureToggles, setSelectedFeatureToggles] = useState({});

  let feature = props.featureToggle;
  let currentState = props.currentState;
  let updateState = props.updateState;

  const handleFeatureToggleSelect = (selectedFeature, value) => {
    const currentFeatureToggles = currentState.user.user.featureToggles;
    let featureToggleObjCopy = {};

    if (value) {
      const updatedFeatureToggles = {
        ...currentFeatureToggles,
        [selectedFeature]: value
      };

      featureToggleObjCopy = updatedFeatureToggles;
    } else {
      const { ...updatedFeatureToggles } = currentFeatureToggles;

      featureToggleObjCopy = updatedFeatureToggles;
    }

    updateState(
      {
        ...currentState,
        user: {
          ...currentState.user,
          user: {
            ...currentState.user.user,
            featureToggles: featureToggleObjCopy
          }
        }
      }
    );
  };

  // const handleFeatureToggleSelect = (selectedFeature) => {
  //   featureIsChecked(!isChecked);
  //   setSelectedFeatureToggles((prev) => {
  //     const updatedSelections = { ...prev };

  //     if (updatedSelections[selectedFeature]) {
  //       delete updatedSelections[selectedFeature];
  //     } else {
  //       updatedSelections[selectedFeature] = true;
  //     }
  //     updateState(
  //       {
  //         ...currentState,
  //         user: {
  //           ...currentState.user,
  //           user: {
  //             ...currentState.user.user,
  //             feature_toggles: updatedSelections
  //           }
  //         }
  //       }
  //     );

  //     return updatedSelections;
  //   });
  // };

  // const onChangeHandle = (value) => {
  //   featureIsChecked(!isChecked);
  //   props.updateState(
  //     {
  //       ...props.currentState,
  //       user: {
  //         ...props.currentState.user,
  //         user: {
  //           ...props.currentState.user.user,
  //           feature_toggles: {
  //             ...props.currentState.user.user.feature_toggles,
  //             [feature]: value
  //           }
  //         }
  //       }
  //     }
  //   );
  // };

  return (
    <div className="load-test-container-checkbox">
      <Checkbox
        label={feature}
        name={feature}
        onChange={(value) => {
          handleFeatureToggleSelect(feature, value);
        }}
        isChecked={Boolean(selectedFeatureToggles[feature])}
        // value={isChecked}
      />
    </div>
  );
}

FeatureToggleConfiguration.propTypes = {
  featureToggle: PropTypes.string,
  currentState: PropTypes.object,
  updateState: PropTypes.func
};
