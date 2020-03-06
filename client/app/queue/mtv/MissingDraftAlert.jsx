import React from 'react';
import PropTypes from 'prop-types';
import Alert from '../../components/Alert';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

const dispositionStrings = {
  denied: 'denial',
  dismissed: 'dismissal'
};

export const MissingDraftAlert = ({ to, disposition = 'denied' }) => (
  <div style={{ maxWidth: '46rem',
    marginBottom: '1.5em' }}>
    <Alert type="warning" title="Please Note">
      If you weren't provided the {dispositionStrings[disposition]} draft ruling letter, please{' '}
      <Link to={to}>return to the motions attorney</Link>.
    </Alert>
  </div>
);

MissingDraftAlert.propTypes = {
  disposition: PropTypes.string,
  to: PropTypes.string.isRequired
};
