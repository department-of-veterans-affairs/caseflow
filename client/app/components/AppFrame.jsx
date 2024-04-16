import React from 'react';
import PropTypes from 'prop-types';
import getAppWidthStyling from
  '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/util/getAppWidthStyling';

import Alert from './Alert';

// eslint-disable-next-line no-process-env
const env = process.env.NODE_ENV;

const AppFrame = ({ children, wideApp }) =>
  <main {...getAppWidthStyling(wideApp)} role="main" id="Main">
    {env !== 'prod' && (<Alert type="warning">This is the {env} environment!</Alert>)}
    {(env !== 'prod' && env === 'demo') && (<Alert type="warning">This is a {env} environment!</Alert>)}

    {children}
  </main>;

AppFrame.propTypes = {
  children: PropTypes.node,
  wideApp: PropTypes.oneOfType([PropTypes.string, PropTypes.bool])
};

export default AppFrame;
