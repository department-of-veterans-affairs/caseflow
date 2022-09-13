import React from 'react';
import getAppWidthStyling from
  '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/util/getAppWidthStyling';

const AppFrame = ({ children, wideApp }) =>
  <main {...getAppWidthStyling(wideApp)} role="main">
    {children}
  </main>;

export default AppFrame;
