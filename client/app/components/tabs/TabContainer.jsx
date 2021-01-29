import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';

import { Tab } from './Tab';

const propTypes = {
  active: PropTypes.string,
  children: PropTypes.arrayOf(PropTypes.element).isRequired,
  idPrefix: PropTypes.string,
  mountOnEnter: PropTypes.bool,
  unmountOnExit: PropTypes.bool,
  onChange: PropTypes.func,
};

export const TabContainer = ({ active = '1', onChange, ...rest }) => {
  const [value, setValue] = useState(active.toString());
  const onSelect = (val) => {
    setValue(val.toString());

    onChange?.(val);
  };

  useEffect(() => setValue(active), [active]);

  return <Tab.Context value={value} onSelect={onSelect} {...rest} />;
};
TabContainer.propTypes = propTypes;
