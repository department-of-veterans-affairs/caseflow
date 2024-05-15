import React from 'react';
import PropTypes from 'prop-types';
import Modal from 'app/components/Modal';
import CurrentIssue from './RequestCommonComponents/CurrentIssue';
import RequestReason from './RequestCommonComponents/RequestReason';
import { useFormContext } from 'react-hook-form';
import RequestIssueFormWrapper from './RequestCommonComponents/RequestIssueFormWrapper';
import PriorDecisionDateAlert from 'app/intakeEdit/components/RequestCommonComponents/PriorDecisionDateAlert';
import PriorDecisionDateSelector from 'app/intakeEdit/components/RequestCommonComponents/PriorDecisionDateSelector';
import IssueDescription from 'app/intakeEdit/components/RequestCommonComponents/IssueDescription';
import IssueTypeSelector from 'app/intakeEdit/components/RequestCommonComponents/IssueTypeSelector';
import * as yup from 'yup';

const modificationSchema = yup.object({
  nonratingIssueCategory: yup.string().required('Please select an issue type.'),
  decisionDate: yup.string().required('Please select a decision date.'),
  decisionText: yup.string().required('Please enter an issue description.'),
  requestReason: yup.string().required('Please enter a request reason.')
});

const RequestIssueModificationContent = (props) => {
  return (
    <div>
      <CurrentIssue currentIssue={props.currentIssue} />
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
