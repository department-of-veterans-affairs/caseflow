import React from 'react';

import { helperLabel } from '../details/style';

export const HelperText = ({ label }) => (
  <span {...helperLabel}>
    {label}
  </span>
);
