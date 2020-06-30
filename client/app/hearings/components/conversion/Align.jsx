
import React from 'react';
import { leftAlign } from '../details/style';

export const LeftAlign = ({ children }) => (
  <div {...leftAlign}>
    {children}
    <div />
  </div>
);
