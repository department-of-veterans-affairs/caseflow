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
  return (
    <div>
      <CurrentIssue currentIssue={props.currentIssue} />

      <RequestReason label="removal" />
    </div>
  );
};

export const RequestIssueRemovalModal = (props) => {

  const combinedProps = {
    schema: removalSchema,
    type: 'removal',
    ...props
  };

  return (
    <RequestIssueFormWrapper {...combinedProps}>
      <RequestIssueRemovalContent {...props} />
    </RequestIssueFormWrapper>
  );
};

RequestIssueRemovalModal.propTypes = {
  onCancel: PropTypes.func,
  currentIssue: PropTypes.object
};

export default RequestIssueRemovalModal;
