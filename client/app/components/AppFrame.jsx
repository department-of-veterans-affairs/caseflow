import React from 'react';
import PropTypes from 'prop-types';
import { Route } from 'react-router-dom';
import getAppWidthStyling from
  '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/util/getAppWidthStyling';
import classnames from 'classnames';

import Alert from './Alert';

// eslint-disable-next-line no-process-env
const env = process.env.DEPLOY_ENV;

const className = classnames(
  {
    'no-env-alert': env !== 'prodtest' && env !== 'preprod' && env !== 'uat' && env !== 'demo',
    'preprod-env-alert': env !== 'prod' && env === 'preprod',
    'prodtest-env-alert': env !== 'prod' && env === 'prodtest',
    'uat-env-alert': env !== 'prod' && env === 'uat',
    'demo-env-alert': env !== 'prod' && env === 'demo',
  },
);

const AppFrame = ({ children, wideApp }) =>
  <main {...getAppWidthStyling(wideApp)} role="main" id="Main">
    <Route
      exact
      path="/"
      title="Caseflow | Home"
      component={() =>
      // eslint-disable-next-line no-undefined
        (env !== 'prod' && env !== 'production' && env !== undefined) &&
      (<div className={className}>
        <Alert type="warning">This is the {env} environment!</Alert>
      </div>)
      } />
    {children}
  </main>;

AppFrame.propTypes = {
  children: PropTypes.node,
  wideApp: PropTypes.oneOfType([PropTypes.string, PropTypes.bool])
};

export default AppFrame;
