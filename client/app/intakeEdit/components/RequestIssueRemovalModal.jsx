import React from 'react';
import PropTypes from 'prop-types';
import { useSelector } from 'react-redux';
import CurrentIssue from './RequestCommonComponents/CurrentIssue';
import RequestReason from './RequestCommonComponents/RequestReason';
import RequestIssueFormWrapper from './RequestCommonComponents/RequestIssueFormWrapper';
import IssueApprovalDenialSection from 'app/intakeEdit/components/RequestCommonComponents/IssueApprovalDenialSection';
import * as yup from 'yup';

const removalSchema = yup.object({
  requestReason: yup.string().required()
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
      {userIsVhaAdmin ? <IssueApprovalDenialSection /> : null}
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
