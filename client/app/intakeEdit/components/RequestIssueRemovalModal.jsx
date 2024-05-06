import React from 'react';
import PropTypes from 'prop-types';
import Modal from 'app/components/Modal';
import CurrentIssue from './RequestCommonComponents/CurrentIssue';
import RequestReason from './RequestCommonComponents/RequestReason';
import { useFormContext } from 'react-hook-form';
import RequestIssueFormWrapper from './RequestCommonComponents/RequestIssueFormWrapper';
import * as yup from 'yup';

const removalSchema = yup.object({
  requestReason: yup.string().required('Please enter a request reason.')
});

const RequestIssueRemovalContent = (props) => {

  const { handleSubmit } = useFormContext();

  const onSubmit = (data) => {
    const enhancedData = {
      requestIssueId: props.currentIssue.id,
      requestType: 'Removal',
      ...data };

    console.log(enhancedData); // add to state later once Sean is done

    props.onCancel();
  };

  return (
    <Modal
      title="Request issue removal"
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

        <RequestReason label="removal" />
      </div>
    </Modal>
  );
};

export const RequestIssueRemovalModal = (props) => {

  return (
    <RequestIssueFormWrapper schema={removalSchema}>
      <RequestIssueRemovalContent {...props} />
    </RequestIssueFormWrapper>
  );
};

RequestIssueRemovalModal.propTypes = {
  onCancel: PropTypes.func,
  currentIssue: PropTypes.object
};

export default RequestIssueRemovalModal;
