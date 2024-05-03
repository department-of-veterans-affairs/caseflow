import React from 'react';
import PropTypes from 'prop-types';
import Modal from 'app/components/Modal';
import CurrentIssue from './RequestCommonComponents/CurrentIssue';
import RequestReason from './RequestCommonComponents/RequestReason';
import { useFormContext } from 'react-hook-form';
import RequestIssueFormWrapper from './RequestCommonComponents/RequestIssueFormWrapper';
import DateSelector from 'app/components/DateSelector';

const RequestIssueWithdrawalContent = (props) => {

  const { handleSubmit, register } = useFormContext();

  const onSubmit = (data) => {
    const enhancedData = {
      requestIssueId: props.currentIssue.id,
      requestType: 'Withdrawal',
      ...data };

    console.log(enhancedData); // add to state later once Sean is done

    props.onCancel();
  };

  return (
    <Modal
      title="Request issue withdrawal"
      buttons={[
        { classNames: ['cf-modal-link', 'cf-btn-link', 'close-modal'],
          name: 'Cancel',
          onClick: props.onCancel
        },
        {
          classNames: ['usa-button', 'usa-button-primary'],
          name: 'Submit request',
          onClick: handleSubmit(onSubmit)
        }
      ]}
      closeHandler={props.onCancel}
    >

      <div>
        <CurrentIssue currentIssue={props.currentIssue} />

        <DateSelector
          label="Request date for withdrawal"
          name="withdrawalDate"
          inputRef={register}
          type="date" />
        <RequestReason
          label="withdrawal" />
      </div>
    </Modal>
  );
};

export const RequestIssueWithdrawalModal = (props) => {

  return (
    <RequestIssueFormWrapper>
      <RequestIssueWithdrawalContent {...props} />
    </RequestIssueFormWrapper>
  );
};

RequestIssueWithdrawalModal.propTypes = {
  onCancel: PropTypes.func,
  currentIssue: PropTypes.object
};

export default RequestIssueWithdrawalModal;
