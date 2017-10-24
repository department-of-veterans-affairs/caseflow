import React from 'react';
import classNames from 'classnames';

const AppSegment = ({ children, className }) =>
  <div className={classNames('cf-app-segment', className)}>
    {children}
  </div>;

export default AppSegment;
