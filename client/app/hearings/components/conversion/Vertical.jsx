
import React from 'react';
import { vertical } from '../details/style';

export const VerticalAlign = ({ children }) => (
  <div {...vertical}>
    {children}
  </div>
);

