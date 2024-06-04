import React from 'react';
import PropTypes from 'prop-types';
import { useForm, FormProvider } from 'react-hook-form';
import { yupResolver } from '@hookform/resolvers/yup';
import Modal from 'app/components/Modal';
import { useSelector } from 'react-redux';
import { formatDateStr, formatDate } from '../../../util/DateUtil';
import uuid from 'uuid';

export const RequestIssueFormWrapper = (props) => {

  const userFullName = useSelector((state) => state.userFullName);
  const userCssId = useSelector((state) => state.userCssId);
  const benefitType = useSelector((state) => state.benefitType);

  const methods = useForm({
    defaultValues: {
      requestReason: props.pendingIssueModificationRequest?.requestReason || '',
      nonratingIssueCategory: props.pendingIssueModificationRequest?.nonratingIssueCategory || '',
      decisionDate: props.pendingIssueModificationRequest?.decisionDate || '',
      nonratingIssueDescription: props.pendingIssueModificationRequest?.nonratingIssueDescription || '',
      withdrawalDate: formatDateStr(formatDate(props.pendingIssueModificationRequest?.withdrawalDate),
        'MM/DD/YYYY', 'YYYY-MM-DD') || ''
    },
    mode: 'onChange',
    resolver: yupResolver(props.schema),
    reValidateMode: 'onSubmit' });

  const { handleSubmit, formState } = methods;

  const onSubmit = (issueModificationRequest) => {
    const currentIssueFields = props.currentIssue ?
      {
        requestIssueId: props.currentIssue.id,
        nonratingIssueCategory: props.currentIssue.category,
        nonratingIssueDescription: props.currentIssue.nonRatingIssueDescription,
        benefitType: props.currentIssue.benefitType,
      } : {};

    // The decision date will come from the current issue for removal and withdrawal requests.
    // Ensure date is in a serializable format for redux
    const decisionDate = formatDateStr(issueModificationRequest.decisionDate) ||
       formatDateStr(props.currentIssue.decisionDate);

    const enhancedData = {
      ...currentIssueFields,
      requestIssue: props.currentIssue,
      ...(props.type === 'addition') && { benefitType },
      requestor: { fullName: userFullName, cssId: userCssId },
      requestType: props.type,
      ...issueModificationRequest,
      decisionDate,
      identifier: uuid.v4()
    };

    // close modal and move the issue
    props.onCancel();

    if (props.type === 'addition') {
      props.addToPendingReviewSection(enhancedData);
    } else {
      props.moveToPendingReviewSection(enhancedData, props.issueIndex);
    }
  };

  return (
    <div>
      <FormProvider {...methods}>
        <form>
          <Modal
            title={`Request issue ${props.type}`}
            buttons={[
              { classNames: ['cf-modal-link', 'cf-btn-link', 'close-modal'],
                name: 'Cancel',
                onClick: props.onCancel
              },
              {
                classNames: ['usa-button', 'usa-button-primary'],
                name: 'Submit request',
                onClick: handleSubmit(onSubmit),
                disabled: !formState.isValid
              }
            ]}
            closeHandler={props.onCancel}
          >
            {props.children}
          </Modal>
        </form>
      </FormProvider>
    </div>
  );
};

RequestIssueFormWrapper.propTypes = {
  onCancel: PropTypes.func,
  children: PropTypes.node,
  currentIssue: PropTypes.object,
  issueIndex: PropTypes.number,
  schema: PropTypes.object,
  type: PropTypes.string,
  moveToPendingReviewSection: PropTypes.func,
  addToPendingReviewSection: PropTypes.func,
  pendingIssueModificationRequest: PropTypes.object
};

export default RequestIssueFormWrapper;
