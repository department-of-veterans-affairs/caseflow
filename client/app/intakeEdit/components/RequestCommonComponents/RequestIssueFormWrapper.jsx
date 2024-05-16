import React from 'react';
import PropTypes from 'prop-types';
import { useForm, FormProvider } from 'react-hook-form';
import { yupResolver } from '@hookform/resolvers/yup';
import Modal from 'app/components/Modal';
import _ from 'lodash';
import { useSelector } from 'react-redux';

export const RequestIssueFormWrapper = (props) => {

  const userDisplayName = useSelector((state) => state.userDisplayName);

  const methods = useForm({ // TODO MONDAY ASK HEATHER: Should we just pre-fill the modal with the existing information?
    defaultValues: {
      requestReason: '',
      nonRatingIssueCategory: '',
      decisionDate: '',
      nonRatingIssueDescription: ''
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
        decisionDate: props.currentIssue.decisionDate
      } : {};

    const enhancedData = {
      ...currentIssueFields,
      ...(props.type === 'modification') && { requestIssue: props.currentIssue },
      requestor: userDisplayName,
      requestType: _.capitalize(props.type),
      ...issueModificationRequest };

    // close modal and move the issue
    props.onCancel();
    props.moveToPendingReviewSection(enhancedData, props.issueIndex);

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
  currentIssue: PropTypes.object,
  issueIndex: PropTypes.number,
  schema: PropTypes.object,
  type: PropTypes.string,
  moveToPendingReviewSection: PropTypes.func
};

export default RequestIssueFormWrapper;
