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
import * as yup from 'yup';

// TODO: move these strings to a constants file
// is it worth DRYing the schemas? probably not
const additionSchema = yup.object({
  nonratingIssueCategory: yup.string().required('Please select an issue type.'),
  decisionDate: yup.string().required('Please select a decision date.'),
  decisionText: yup.string().required('Please enter an issue description.'),
  requestReason: yup.string().required('Please enter a request reason.')
});

const RequestIssueAdditionContent = (props) => {

  const { handleSubmit, formState } = useFormContext();

  const onSubmit = (data) => {
    const enhancedData = {
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
          onClick: handleSubmit(onSubmit),
          disabled: !formState.isValid
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
};
export const RequestIssueAdditionModal = (props) => {

  return (
    <RequestIssueFormWrapper schema={additionSchema}>
      <RequestIssueAdditionContent {...props} />
    </RequestIssueFormWrapper>
  );
};

export default RequestIssueAdditionModal;
