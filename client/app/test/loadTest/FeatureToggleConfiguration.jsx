/* eslint-disable max-lines, max-len */

import React, { useState } from 'react';
import PropTypes from 'prop-types';

import Checkbox from '../../components/Checkbox';

export default function FeatureToggleConfiguration(props) {
  const [isChecked, featureIsChecked] = useState(false);

  let feature = props.featureToggle;

  const onChangeHandle = () => {
    featureIsChecked(!isChecked);
  };

  return (
    <div className="load-test-container-checkbox">
      <Checkbox
        label={feature}
        name={feature}
        onChange={() => {
          onChangeHandle();
        }}
        value={isChecked}
      />
    </div>
  );
}

FeatureToggleConfiguration.propTypes = {
  featureToggle: PropTypes.string
};
