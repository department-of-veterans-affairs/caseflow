import React from 'react';
import { marginTop } from './style';

export const ReadOnly = ({ label, children }) => (
  <div {...marginTop(25)}>
    <strong>{label}</strong>
    {children}
  </div>
);
