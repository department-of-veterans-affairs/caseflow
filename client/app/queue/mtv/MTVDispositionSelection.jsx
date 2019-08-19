import React, { useState } from 'react';
import PropTypes from 'prop-types';
import RadioField from '../../components/RadioField';

import { mtvDispositionOptions } from './index';

export const MTVDispositionSelection = ({ label = '', value: initialVal = null }) => {
  const [value, setValue] = useState(initialVal);

  return (
    <RadioField
      name="disposition"
      label={label}
      options={mtvDispositionOptions}
      onChange={(val) => setValue(val)}
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
