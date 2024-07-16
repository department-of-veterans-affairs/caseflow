import React from 'react';
import PropTypes from 'prop-types';
import { useSelector } from 'react-redux';
import CurrentIssue from './RequestCommonComponents/CurrentIssue';
import RequestReason from './RequestCommonComponents/RequestReason';
import RequestIssueFormWrapper from './RequestCommonComponents/RequestIssueFormWrapper';
import PriorDecisionDateAlert from 'app/intakeEdit/components/RequestCommonComponents/PriorDecisionDateAlert';
import PriorDecisionDateSelector from 'app/intakeEdit/components/RequestCommonComponents/PriorDecisionDateSelector';
import IssueDescription from 'app/intakeEdit/components/RequestCommonComponents/IssueDescription';
import IssueTypeSelector from 'app/intakeEdit/components/RequestCommonComponents/IssueTypeSelector';
import {
  RequestIssueStatus,
  statusSchema,
  decisionReasonSchema
} from 'app/intakeEdit/components/RequestCommonComponents/RequestIssueStatus';
import * as yup from 'yup';

const modificationSchema = yup.object().shape({
  nonratingIssueCategory: yup.string().required(),
  decisionDate: yup.date().required().
    max(new Date(), 'Decision date cannot be in the future.'),
  nonratingIssueDescription: yup.string().required(),
  requestReason: yup.string().required(),
  status: statusSchema,
  decisionReason: decisionReasonSchema
});

const RequestIssueModificationContent = ({ currentIssue, pendingIssueModificationRequest }) => {
  const originalIssue = pendingIssueModificationRequest?.requestIssue || currentIssue;
  const userIsVhaAdmin = useSelector((state) => state.userIsVhaAdmin);
  const currentIssueTitle = (userIsVhaAdmin) ?
    'Original issue' : 'Current issue';

  return (
    <div>
      <CurrentIssue currentIssue={originalIssue} title={currentIssueTitle} />
      <IssueTypeSelector />
      <PriorDecisionDateAlert />
      <PriorDecisionDateSelector />
      <IssueDescription />
      <RequestReason label="modification" />
      {userIsVhaAdmin ? <RequestIssueStatus displayCheckbox /> : null }
    </div>
  );
};

RequestIssueModificationContent.propTypes = {
  onCancel: PropTypes.func,
  currentIssue: PropTypes.object,
  pendingIssueModificationRequest: PropTypes.object
};
export const RequestIssueModificationModal = (props) => {

  const combinedProps = {
    schema: modificationSchema,
    type: 'modification',
    ...props
  };

  return (
    <RequestIssueFormWrapper {...combinedProps}>
      <RequestIssueModificationContent {...props} />
    </RequestIssueFormWrapper>
  );
};

export default RequestIssueModificationModal;
