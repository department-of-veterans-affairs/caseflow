import React from 'react';
import PropTypes from 'prop-types';
import Alert from '../../components/Alert';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

export const ReturnToLitSupportAlert = ({ to }) => (
  <div style={{ maxWidth: '46rem', marginBottom: '1.5em' }}>
    <Alert type="warning" title="Please Note">
      If you weren't provided the draft ruling letter, or would like to request that the motions attorney make changes,
      please <Link to={to}>return to the motions attorney</Link>.
    </Alert>
  </div>
);

ReturnToLitSupportAlert.propTypes = {
  to: PropTypes.string.isRequired
};
