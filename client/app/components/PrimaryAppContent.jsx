import React from 'react';
import classNames from 'classnames';

// extraClassNames is only to help with migration, but should not be used for new code.
// We should be adding properties to PrimaryAppContent and applying styling within this
// component, instead of applying new class names.
const PrimaryAppContent = ({ children, extraClassNames }) =>
  <div className={classNames("cf-app-segment cf-app-segment--alt", extraClassNames)}>
    {children}
  </div>;

export default PrimaryAppContent;
