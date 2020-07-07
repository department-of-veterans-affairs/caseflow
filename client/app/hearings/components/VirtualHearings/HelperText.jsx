import React from 'react';
import PropTypes from 'prop-types';

import { helperLabel } from '../details/style';

export const HelperText = ({ label }) => (
  <span {...helperLabel}>
    {label}
  </span>
);

HelperText.propTypes = {
  label: PropTypes.string,
};
