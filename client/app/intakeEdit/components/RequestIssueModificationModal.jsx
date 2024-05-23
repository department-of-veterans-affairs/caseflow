import React from 'react';
import PropTypes from 'prop-types';
import CurrentIssue from './RequestCommonComponents/CurrentIssue';
import RequestReason from './RequestCommonComponents/RequestReason';
import RequestIssueFormWrapper from './RequestCommonComponents/RequestIssueFormWrapper';
import PriorDecisionDateAlert from 'app/intakeEdit/components/RequestCommonComponents/PriorDecisionDateAlert';
import PriorDecisionDateSelector from 'app/intakeEdit/components/RequestCommonComponents/PriorDecisionDateSelector';
import IssueDescription from 'app/intakeEdit/components/RequestCommonComponents/IssueDescription';
import IssueTypeSelector from 'app/intakeEdit/components/RequestCommonComponents/IssueTypeSelector';
import * as yup from 'yup';

const modificationSchema = yup.object({
  nonRatingIssueCategory: yup.string().required(),
  decisionDate: yup.date().required().
    max(new Date(), 'Decision date cannot be in the future.'),
  nonRatingIssueDescription: yup.string().required(),
  requestReason: yup.string().required()
});

const RequestIssueModificationContent = ({ currentIssue }) => {
  return (
    <div>
      <CurrentIssue currentIssue={currentIssue} />
      <IssueTypeSelector />
      <PriorDecisionDateAlert />
      <PriorDecisionDateSelector />
      <IssueDescription />
      <RequestReason label="modification" />
    </div>
  );
};

RequestIssueModificationContent.propTypes = {
  onCancel: PropTypes.func,
  currentIssue: PropTypes.object
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
