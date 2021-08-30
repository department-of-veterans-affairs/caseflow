import React from 'react';
import PropTypes from 'prop-types';
import { Link } from 'react-router-dom';
import Alert from 'app/components/Alert';

import { SUBSTITUTE_APPELLANT_SOURCE_APPEAL_ALERT_DESCRIPTION } from 'app/../COPY';

export const AppealHasSubstitutionAlert = ({ targetAppealId }) => {
  return (
    <Alert type="info">
      {SUBSTITUTE_APPELLANT_SOURCE_APPEAL_ALERT_DESCRIPTION}{' '}
      <span>
        See the new{' '}
        <Link to={`/queue/appeals/${targetAppealId}`}>appeal stream</Link>.
      </span>
    </Alert>
  );
};

AppealHasSubstitutionAlert.propTypes = {
  targetAppealId: PropTypes.string.isRequired,
};
