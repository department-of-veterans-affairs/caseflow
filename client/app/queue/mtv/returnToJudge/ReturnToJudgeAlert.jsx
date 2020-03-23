import React from 'react';
import PropTypes from 'prop-types';

import Alert from '../../../components/Alert';
import { MTV_CHECKOUT_RETURN_TO_JUDGE_ALERT_TITLE } from '../../../../COPY';
import { REVIEW_VACATE_RETURN_TO_JUDGE } from '../../../../constants/TASK_ACTIONS';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

export const ReturnToJudgeAlert = ({ to = `review_vacatures/${REVIEW_VACATE_RETURN_TO_JUDGE.value}` }) => {
  return (
    <Alert type="info" title={MTV_CHECKOUT_RETURN_TO_JUDGE_ALERT_TITLE}>
      Listed here are the prior decision issues marked for vacatur by the judge who assigned this case to you. These
      cannot be edited and if you believe there is an error, <Link to={to}>please return to the judge</Link>.
    </Alert>
  );
};

ReturnToJudgeAlert.propTypes = {
  to: PropTypes.string
};
