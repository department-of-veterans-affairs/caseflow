import React from 'react';
import PropTypes from 'prop-types';
import Modal from 'app/components/Modal';
import RequestReason from './RequestCommonComponents/RequestReason';
import { useFormContext } from 'react-hook-form';
import RequestIssueFormWrapper from './RequestCommonComponents/RequestIssueFormWrapper';
import IssueTypeSelector from './RequestCommonComponents/IssueTypeSelector';
import PriorDecisionDateAlert from './RequestCommonComponents/PriorDecisionDateAlert';
import PriorDecisionDateSelector from './RequestCommonComponents/PriorDecisionDateSelector';
import IssueDescription from './RequestCommonComponents/IssueDescription';

const RequestIssueAdditionContent = (props) => {

  const { handleSubmit } = useFormContext();

  const onSubmit = (data) => {
    const enhancedData = {
      requestIssueId: props.currentIssue.id,
      requestType: 'Addition',
      ...data };

    console.log(enhancedData); // add to state later once Sean is done

    props.onCancel();
  };

  return (
    <Modal
      title="Request issue addition"
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
        <IssueTypeSelector />
        <PriorDecisionDateAlert />
        <PriorDecisionDateSelector />
        <IssueDescription />
        <RequestReason label="addition" />
      </div>
    </Modal>
  );
};

RequestIssueAdditionContent.propTypes = {
  onCancel: PropTypes.func,
  currentIssue: PropTypes.object
};
export const RequestIssueAdditionModal = (props) => {

  return (
    <RequestIssueFormWrapper>
      <RequestIssueAdditionContent {...props} />
    </RequestIssueFormWrapper>
  );
};

export default RequestIssueAdditionModal;
