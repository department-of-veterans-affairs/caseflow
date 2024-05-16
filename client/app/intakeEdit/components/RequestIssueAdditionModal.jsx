import React from 'react';
import PropTypes from 'prop-types';
import RequestReason from './RequestCommonComponents/RequestReason';
import RequestIssueFormWrapper from './RequestCommonComponents/RequestIssueFormWrapper';
import IssueTypeSelector from './RequestCommonComponents/IssueTypeSelector';
import PriorDecisionDateAlert from './RequestCommonComponents/PriorDecisionDateAlert';
import PriorDecisionDateSelector from './RequestCommonComponents/PriorDecisionDateSelector';
import IssueDescription from './RequestCommonComponents/IssueDescription';
import * as yup from 'yup';

const additionSchema = yup.object({
  nonRatingIssueCategory: yup.string().required('Please select an issue type.'),
  decisionDate: yup.string().required('Please select a decision date.'),
  nonRatingIssueDescription: yup.string().required('Please enter an issue description.'),
  requestReason: yup.string().required('Please enter a request reason.')
});

const RequestIssueAdditionContent = () => {
  return (
    <div>
      <IssueTypeSelector />
      <PriorDecisionDateAlert />
      <PriorDecisionDateSelector />
      <IssueDescription />
      <RequestReason label="addition" />
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
