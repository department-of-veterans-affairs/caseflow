import React from 'react';
import PropTypes from 'prop-types';
import { Link } from 'react-router-dom';
import Alert from 'app/components/Alert';

import { SUBSTITUTE_APPELLANT_SOURCE_APPEAL_ALERT_DESCRIPTION } from 'app/../COPY';

const appealIsSameAppealSubstitution = ({ targetAppealId }) => {
  return (targetAppealId === 'undefined' || targetAppealId === null);
};

export const AppealHasSubstitutionAlert = ({ targetAppealId }) => {
  return (
    <Alert type="info">
      {SUBSTITUTE_APPELLANT_SOURCE_APPEAL_ALERT_DESCRIPTION}{' '}
      {!appealIsSameAppealSubstitution &&
      <span>
          See the new{' '}
        <Link to={`/queue/appeals/${targetAppealId}`}>appeal stream</Link>.
      </span>
      }
    </Alert>
  );
};

AppealHasSubstitutionAlert.propTypes = {
  targetAppealId: PropTypes.string.isRequired,
};
