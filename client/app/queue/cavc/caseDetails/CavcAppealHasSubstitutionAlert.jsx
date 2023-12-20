import React from 'react';
import PropTypes from 'prop-types';
import { Link } from 'react-router-dom';
import Alert from 'app/components/Alert';

import { CAVC_REMAND_REVIEW_SOURCE_APPEAL_ALERT_DESCRIPTION } from 'app/../COPY';

export const CavcAppealHasSubstitutionAlert = ({ targetAppealId }) => {

  return (
    <Alert type="info">
      {CAVC_REMAND_REVIEW_SOURCE_APPEAL_ALERT_DESCRIPTION}{' '}
      {targetAppealId && (
        <span>
          See the new{' '}
          <Link to={`/queue/appeals/${targetAppealId}`}>appeal stream</Link>.
        </span>
      )}
    </Alert>
  );
};

CavcAppealHasSubstitutionAlert.propTypes = {
  targetAppealId: PropTypes.string.isRequired
};
