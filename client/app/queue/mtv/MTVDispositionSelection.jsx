import React, { useState } from 'react';
import PropTypes from 'prop-types';
import RadioField from '../../components/RadioField';

import { mtvDispositionOptions } from './index';

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
      options={mtvDispositionOptions}
      onChange={handleChange}
      value={value}
      className={['mtv-disposition-selection']}
    />
  );
};

MTVDispositionSelection.propTypes = {
  onChange: PropTypes.func,
  value: PropTypes.string,
  label: PropTypes.string
};
