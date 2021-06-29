import React from 'react';
import PropTypes from 'prop-types';

import { helperLabel } from '../details/style';

export const HelperText = ({ label }) => (
  <div {...helperLabel}>
    {label}
  </div>
);

HelperText.propTypes = {
  label: PropTypes.string,
};
