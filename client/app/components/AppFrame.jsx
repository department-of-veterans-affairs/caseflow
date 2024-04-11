import React from 'react';
import PropTypes from 'prop-types';
import getAppWidthStyling from
  '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/util/getAppWidthStyling';

import Alert from './Alert';

const env = process.env.NODE_ENV;

const AppFrame = ({ children, wideApp }) =>
  <main {...getAppWidthStyling(wideApp)} role="main" id="Main">
    {env === 'development' && (<Alert type="success">This is the {env} environment!</Alert>)}
    {env === 'uat' && (<Alert type="info">This is the {env} environment!</Alert>)}
    {env === 'preprod' && (<Alert type="warning">This is the {env} environment!</Alert>)}
    {env === 'prodtest' && (<Alert type="error">This is the {env} environment!</Alert>)}

    {children}
  </main>;

AppFrame.propTypes = {
  children: PropTypes.node,
  wideApp: PropTypes.oneOfType([PropTypes.string, PropTypes.bool])
};

export default AppFrame;
