import React from 'react';
import PropTypes from 'prop-types';
import { useSelector } from 'react-redux';
import CurrentIssue from './RequestCommonComponents/CurrentIssue';
import RequestReason from './RequestCommonComponents/RequestReason';
import { useFormContext } from 'react-hook-form';
import RequestIssueFormWrapper from './RequestCommonComponents/RequestIssueFormWrapper';
import DateSelector from 'app/components/DateSelector';
import {
  RequestIssueStatus,
  statusSchema,
  decisionReasonSchema
} from 'app/intakeEdit/components/RequestCommonComponents/RequestIssueStatus';
import * as yup from 'yup';

const withdrawalSchema = yup.object().shape({
  requestReason: yup.string().required(),
  withdrawalDate: yup.date().required().
    max(new Date(), 'We cannot process your request. Please select a date prior to today\'s date.'),
  status: statusSchema,
  decisionReason: decisionReasonSchema
});

const RequestIssueWithdrawalContent = ({ currentIssue, pendingIssueModificationRequest }) => {

  const originalIssue = pendingIssueModificationRequest?.requestIssue || currentIssue;
  const userIsVhaAdmin = useSelector((state) => state.userIsVhaAdmin);

  const { register, errors } = useFormContext();

  const currentIssueTitle = (userIsVhaAdmin) ?
    'Original issue' : 'Current issue';

  return (
    <div>
      <CurrentIssue currentIssue={originalIssue} title={currentIssueTitle} />

      <DateSelector
        label="Request date for withdrawal"
        name="withdrawalDate"
        inputRef={register}
        errorMessage={errors.withdrawalDate?.message}
        type="date" />
      <RequestReason
        label="withdrawal" />
      {userIsVhaAdmin ? <RequestIssueStatus /> : null}
    </div>
  );
};

RequestIssueWithdrawalContent.propTypes = {
  currentIssue: PropTypes.object,
  pendingIssueModificationRequest: PropTypes.object
};

export const RequestIssueWithdrawalModal = (props) => {

  const combinedProps = {
    schema: withdrawalSchema,
    type: 'withdrawal',
    ...props
  };

  return (
    <RequestIssueFormWrapper {...combinedProps}>
      <RequestIssueWithdrawalContent {...props} />
    </RequestIssueFormWrapper>
  );
};

RequestIssueWithdrawalModal.propTypes = {
  onCancel: PropTypes.func,
  currentIssue: PropTypes.object
};

export default RequestIssueWithdrawalModal;
