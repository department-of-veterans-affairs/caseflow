import React from 'react';
import PropTypes from 'prop-types';
import Modal from 'app/components/Modal';
import CurrentIssue from './RequestCommonComponents/CurrentIssue';
import RequestReason from './RequestCommonComponents/RequestReason';
import { useFormContext } from 'react-hook-form';
import RequestIssueFormWrapper from './RequestCommonComponents/RequestIssueFormWrapper';
import PriorDecisionDateAlert from 'app/intakeEdit/components/RequestCommonComponents/PriorDecisionDateAlert';
import PriorDecisionDateSelector from 'app/intakeEdit/components/RequestCommonComponents/PriorDecisionDateSelector';
import IssueDescription from 'app/intakeEdit/components/RequestCommonComponents/IssueDescription';
import IssueTypeSelector from 'app/intakeEdit/components/RequestCommonComponents/IssueTypeSelector';
import * as yup from 'yup';

const modificationSchema = yup.object({
  nonratingIssueCategory: yup.string().required('Please select an issue type.'),
  decisionDate: yup.string().required('Please select a decision date.'),
  decisionText: yup.string().required('Please enter an issue description.'),
  requestReason: yup.string().required('Please enter a request reason.')
});

const RequestIssueModificationContent = (props) => {

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
      title="Request issue modification"
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
        <IssueTypeSelector />
        <PriorDecisionDateAlert />
        <PriorDecisionDateSelector />
        <IssueDescription />
        <RequestReason label="modification" />
      </div>
    </Modal>
  );
};

RequestIssueModificationContent.propTypes = {
  onCancel: PropTypes.func,
  currentIssue: PropTypes.object
};
export const RequestIssueModificationModal = (props) => {

  return (
    <RequestIssueFormWrapper schema={modificationSchema}>
      <RequestIssueModificationContent {...props} />
    </RequestIssueFormWrapper>
  );
};

export default RequestIssueModificationModal;
