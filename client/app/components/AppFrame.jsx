import React from 'react';
import PropTypes from 'prop-types';
import getAppWidthStyling from
  '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/util/getAppWidthStyling';
import classnames from 'classnames';

import Alert from './Alert';

// eslint-disable-next-line no-process-env
// const env = process.env.DEPLOY_ENV;

const env = 'uat';

const className = classnames(
  {
    // eslint-disable-next-line no-undefined
    'dev-env-alert': env !== 'prod' && env === undefined,
    'prodtest-env-alert': env !== 'prod' && env === 'prodtest',
    'preprod-env-alert': env !== 'prod' && env === 'preprod',
    'uat-env-alert': env !== 'prod' && env === 'uat',
    'demo-env-alert': env !== 'prod' && env === 'demo',
  },
);

const AppFrame = ({ children, wideApp }) =>
  <main {...getAppWidthStyling(wideApp)} role="main" id="Main">
    {
      // eslint-disable-next-line no-undefined
      (env !== 'prod' && env !== 'production' && env !== undefined && env !== 'demo') &&
      (<div className={className}>
        <Alert type="warning">This is the {env} environment!</Alert>
      </div>)
    }
    {
      (env !== 'prod' && env !== 'production' && env === 'demo') &&
      (<div className={className}>
        <Alert type="warning">This is a {env} environment!</Alert>
      </div>)
    }
    {children}
  </main>;

AppFrame.propTypes = {
  children: PropTypes.node,
  wideApp: PropTypes.oneOfType([PropTypes.string, PropTypes.bool])
};

export default AppFrame;
