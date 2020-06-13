import React, { useState } from 'react';
import PropTypes from 'prop-types';

import { Tab } from './Tab';

const propTypes = {
  active: PropTypes.string,
  children: PropTypes.arrayOf(PropTypes.element).isRequired,
};

export const TabContainer = ({ active = '1', children }) => {
  const [value, setValue] = useState(active);
  const onSelect = (val) => setValue(val);

  return (
    <Tab.Context value={value} onSelect={onSelect}>
      {children}
    </Tab.Context>
  );
};
TabContainer.propTypes = propTypes;
