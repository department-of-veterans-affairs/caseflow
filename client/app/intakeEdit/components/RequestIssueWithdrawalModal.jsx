import React from 'react';
import PropTypes from 'prop-types';
import CurrentIssue from './RequestCommonComponents/CurrentIssue';
import RequestReason from './RequestCommonComponents/RequestReason';
import { useFormContext } from 'react-hook-form';
import RequestIssueFormWrapper from './RequestCommonComponents/RequestIssueFormWrapper';
import DateSelector from 'app/components/DateSelector';
import * as yup from 'yup';

const withdrawalSchema = yup.object({
  requestReason: yup.string().required('Please enter a request reason.'),
  withdrawalDate: yup.string().required('Please enter a withdrawal date.')
});

const RequestIssueWithdrawalContent = (props) => {

  const { register, errors } = useFormContext();

  return (
    <div>
      <CurrentIssue currentIssue={props.currentIssue} />

      <DateSelector
        label="Request date for withdrawal"
        name="withdrawalDate"
        inputRef={register}
        errorMessage={errors.withdrawalDate?.message}
        type="date" />
      <RequestReason
        label="withdrawal" />
    </div>
  );
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
