/* eslint-disable max-lines, max-len */

import React, { useState } from 'react';
import PropTypes from 'prop-types';

import Checkbox from '../../components/Checkbox';

export default function FunctionConfiguration(props) {
  const [isChecked, functionIsChecked] = useState(false);

  let functionOption = props.functionOption;

  const onChangeHandle = () => {
    functionIsChecked(!isChecked);
  };

  return (
    <div>
      <Checkbox
        label={functionOption}
        name={functionOption}
        onChange={() => {
          onChangeHandle();
        }}
        value={isChecked}
      />
    </div>
  );
}

FunctionConfiguration.propTypes = {
  functionOption: PropTypes.string
};
