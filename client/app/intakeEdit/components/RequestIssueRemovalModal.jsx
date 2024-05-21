import React from 'react';
import PropTypes from 'prop-types';
import CurrentIssue from './RequestCommonComponents/CurrentIssue';
import RequestReason from './RequestCommonComponents/RequestReason';
import RequestIssueFormWrapper from './RequestCommonComponents/RequestIssueFormWrapper';
import * as yup from 'yup';

const removalSchema = yup.object({
  requestReason: yup.string().required()
});

const RequestIssueRemovalContent = ({ currentIssue }) => {
  return (
    <div>
      <CurrentIssue currentIssue={currentIssue} />

      <RequestReason label="removal" />
    </div>
  );
};

RequestIssueRemovalContent.propTypes = {
  currentIssue: PropTypes.object
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
