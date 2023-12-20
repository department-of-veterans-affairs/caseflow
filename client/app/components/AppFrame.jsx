import React from 'react';
import PropTypes from 'prop-types';
import getAppWidthStyling from
  '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/util/getAppWidthStyling';

const AppFrame = ({ children, wideApp }) =>
  <main {...getAppWidthStyling(wideApp)} role="main" id="Main">
    {children}
  </main>;

AppFrame.propTypes = {
  children: PropTypes.node,
  wideApp: PropTypes.oneOfType([PropTypes.string, PropTypes.bool])
};

export default AppFrame;
