import React from 'react';
import getAppWidthStyling from
  '@department-of-veterans-affairs/appeals-frontend-toolkit/components/util/getAppWidthStyling';

const AppFrame = ({ children, wideApp }) =>
  <main {...getAppWidthStyling(wideApp)}>
    {children}
  </main>;

export default AppFrame;
