import React from 'react';
import PropTypes from 'prop-types';
import { useSelector } from 'react-redux';
import RequestReason from './RequestCommonComponents/RequestReason';
import RequestIssueFormWrapper from './RequestCommonComponents/RequestIssueFormWrapper';
import IssueTypeSelector from './RequestCommonComponents/IssueTypeSelector';
import PriorDecisionDateAlert from './RequestCommonComponents/PriorDecisionDateAlert';
import PriorDecisionDateSelector from './RequestCommonComponents/PriorDecisionDateSelector';
import IssueDescription from './RequestCommonComponents/IssueDescription';
import {
  RequestIssueStatus,
  statusSchema,
  decisionReasonSchema
} from 'app/intakeEdit/components/RequestCommonComponents/RequestIssueStatus';
import * as yup from 'yup';

const additionSchema = yup.object().shape({
  nonratingIssueCategory: yup.string().required(),
  decisionDate: yup.date().required().
    max(new Date(), 'Decision date cannot be in the future.'),
  nonratingIssueDescription: yup.string().required(),
  requestReason: yup.string().required(),
  status: statusSchema,
  decisionReason: decisionReasonSchema
});

const RequestIssueAdditionContent = () => {
  const userIsVhaAdmin = useSelector((state) => state.userIsVhaAdmin);

  return (
    <div>
      <IssueTypeSelector />
      <PriorDecisionDateAlert />
      <PriorDecisionDateSelector />
      <IssueDescription />
      <RequestReason label="addition" />
      {userIsVhaAdmin ? <RequestIssueStatus /> : null}
    </div>
  );
};

RequestIssueAdditionContent.propTypes = {
  onCancel: PropTypes.func,
};
export const RequestIssueAdditionModal = (props) => {

  const combinedProps = {
    schema: additionSchema,
    type: 'addition',
    ...props
  };

  return (
    <RequestIssueFormWrapper {...combinedProps}>
      <RequestIssueAdditionContent />
    </RequestIssueFormWrapper>
  );
};

export default RequestIssueAdditionModal;
