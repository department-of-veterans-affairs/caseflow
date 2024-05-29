import React from 'react';
import PropTypes from 'prop-types';
import { useForm, FormProvider } from 'react-hook-form';
import { yupResolver } from '@hookform/resolvers/yup';
import Modal from 'app/components/Modal';
import { useSelector } from 'react-redux';
import { formatDateStr } from '../../../util/DateUtil';

export const RequestIssueFormWrapper = (props) => {

  const userFullName = useSelector((state) => state.userFullName);
  const userCssId = useSelector((state) => state.userCssId);
  const benefitType = useSelector((state) => state.benefitType);

  const methods = useForm({
    defaultValues: {
      requestReason: '',
      nonratingIssueCategory: '',
      decisionDate: '',
      nonratingIssueDescription: ''
    },
    mode: 'onChange',
    resolver: yupResolver(props.schema),
    reValidateMode: 'onSubmit' });

  const { handleSubmit, formState } = methods;

  const onSubmit = (issueModificationRequest) => {
    const currentIssueFields = props.currentIssue ?
      {
        requestIssueId: props.currentIssue.id,
        nonRatingIssueCategory: props.currentIssue.category,
        nonRatingIssueDescription: props.currentIssue.nonRatingIssueDescription,
        benefitType: props.currentIssue.benefitType,
        decisionDate: formatDateStr(props.currentIssue.decisionDate)
      } : {};

    const enhancedData = {
      ...currentIssueFields,
      ...(props.type === 'modification') && { requestIssue: props.currentIssue },
      ...(props.type === 'addition') && { benefitType },
      requestor: { fullName: userFullName, cssId: userCssId },
      requestType: props.type,
      ...issueModificationRequest,
      // Ensure date is in a serializable format
      decisionDate: formatDateStr(issueModificationRequest.decisionDate)
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
  addToPendingReviewSection: PropTypes.func
};

export default RequestIssueFormWrapper;
