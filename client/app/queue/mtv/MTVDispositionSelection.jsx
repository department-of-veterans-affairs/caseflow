import React, { useState } from 'react';
import PropTypes from 'prop-types';
import RadioField from '../../components/RadioField';

import { DISPOSITION_OPTIONS } from '../../../constants/MOTION_TO_VACATE';

export const MTVDispositionSelection = ({ label = '', value: initialVal = null, onChange }) => {
  const [value, setValue] = useState(initialVal);

  const handleChange = (val) => {
    setValue(val);
    if (onChange) {
      onChange(val);
    }
  };

  return (
    <RadioField
      name="disposition"
      label={label}
      options={DISPOSITION_OPTIONS}
      onChange={handleChange}
      value={value}
      strongLabel
      className={['mtv-disposition-selection']}
    />
  );
};

MTVDispositionSelection.propTypes = {
  onChange: PropTypes.func,
  value: PropTypes.string,
  label: PropTypes.string
};
