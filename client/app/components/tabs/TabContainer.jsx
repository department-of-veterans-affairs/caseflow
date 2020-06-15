import React, { useState } from 'react';
import PropTypes from 'prop-types';

import { Tab } from './Tab';

const propTypes = {
  active: PropTypes.string,
  children: PropTypes.arrayOf(PropTypes.element).isRequired,
  idPrefix: PropTypes.string,
};

export const TabContainer = ({ active = '1', children, idPrefix }) => {
  const [value, setValue] = useState(active.toString());
  const onSelect = (val) => setValue(val.toString());

  return (
    <Tab.Context value={value} onSelect={onSelect} idPrefix={idPrefix}>
      {children}
    </Tab.Context>
  );
};
TabContainer.propTypes = propTypes;
