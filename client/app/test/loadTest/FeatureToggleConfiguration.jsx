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
    <div>
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
