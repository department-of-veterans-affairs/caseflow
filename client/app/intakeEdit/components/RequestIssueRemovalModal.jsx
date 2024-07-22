import React from 'react';
import PropTypes from 'prop-types';
import { useSelector } from 'react-redux';
import CurrentIssue from './RequestCommonComponents/CurrentIssue';
import RequestReason from './RequestCommonComponents/RequestReason';
import RequestIssueFormWrapper from './RequestCommonComponents/RequestIssueFormWrapper';
import {
  RequestIssueStatus,
  statusSchema,
  decisionReasonSchema
} from 'app/intakeEdit/components/RequestCommonComponents/RequestIssueStatus';
import * as yup from 'yup';

const removalSchema = yup.object().shape({
  requestReason: yup.string().required(),
  status: statusSchema,
  decisionReason: decisionReasonSchema
});

const RequestIssueRemovalContent = ({
  currentIssue,
  pendingIssueModificationRequest
}) => {
  const originalIssue = pendingIssueModificationRequest?.requestIssue || currentIssue;
  const userIsVhaAdmin = useSelector((state) => state.userIsVhaAdmin);

  const currentIssueTitle = (userIsVhaAdmin) ?
    'Original issue' : 'Current issue';

  return (
    <div>
      <CurrentIssue currentIssue={originalIssue} title={currentIssueTitle} />

      <RequestReason label="removal" />
      {userIsVhaAdmin ? <RequestIssueStatus /> : null}
    </div>
  );
};

RequestIssueRemovalContent.propTypes = {
  currentIssue: PropTypes.object,
  pendingIssueModificationRequest: PropTypes.object,
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

export default RequestIssueRemovalModal;

RequestIssueRemovalModal.propTypes = {
  onCancel: PropTypes.func,
  currentIssue: PropTypes.object
};
