import React, { useState } from 'react';
import PropTypes from 'prop-types';
import RadioField from '../../components/RadioField';

import { DISPOSITION_OPTIONS, PARTIAL_GRANT_OPTION } from '../../../constants/MOTION_TO_VACATE';

// In certain cases (judge view) we want to include a "partial grant" option
const [grant, ...rest] = DISPOSITION_OPTIONS;
const optsWithPartial = [grant, PARTIAL_GRANT_OPTION, ...rest];

export const MTVDispositionSelection = ({ label = '', value: initialVal = null, onChange, allowPartial = false }) => {
  const [value, setValue] = useState(initialVal);

  const handleChange = (val) => {
    setValue(val);
    if (onChange) {
      onChange(val);
    }
  };

  const options = allowPartial ? optsWithPartial : DISPOSITION_OPTIONS;

  return (
    <RadioField
      name="disposition"
      label={label}
      options={options}
      onChange={handleChange}
      value={value}
      required
      className={['mtv-disposition-selection']}
    />
  );
};

MTVDispositionSelection.propTypes = {
  onChange: PropTypes.func,
  value: PropTypes.string,
  label: PropTypes.string,
  allowPartial: PropTypes.bool
};
