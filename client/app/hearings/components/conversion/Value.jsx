import React from 'react';
import { marginTop } from '../details/style';

export const DisplayValue = ({ label, children }) => (
  <div {...marginTop(25)}>
    <strong>{label}</strong>
    {children}
  </div>
);
