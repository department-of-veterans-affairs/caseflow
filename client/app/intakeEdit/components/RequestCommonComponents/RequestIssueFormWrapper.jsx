import React from 'react';
import PropTypes from 'prop-types';
import { useForm, FormProvider } from 'react-hook-form';
import { yupResolver } from '@hookform/resolvers/yup';
import Modal from 'app/components/Modal';
import { useSelector, useDispatch } from 'react-redux';
import { formatDateStr, formatDate, getDisplayTime } from '../../../util/DateUtil';
import uuid from 'uuid';
import {
  adminWithdrawRequestIssue,
  toggleIssueRemoveModal,
  updatePendingReview,
  adminAddRequestIssue
} from 'app/intake/actions/addIssues';
import { convertPendingIssueToRequestIssue } from 'app/intake/util/issueModificationRequests';

export const RequestIssueFormWrapper = (props) => {

  const userFullName = useSelector((state) => state.userFullName);
  const userCssId = useSelector((state) => state.userCssId);
  const benefitType = useSelector((state) => state.benefitType);
  const userIsVhaAdmin = useSelector((state) => state.userIsVhaAdmin);
  const addedIssues = useSelector((state) => state.addedIssues);
  const dispatch = useDispatch();

  const methods = useForm({
    defaultValues: {
      requestReason: props.pendingIssueModificationRequest?.requestReason || '',
      nonratingIssueCategory: props.pendingIssueModificationRequest?.nonratingIssueCategory || '',
      decisionDate: props.pendingIssueModificationRequest?.decisionDate || '',
      nonratingIssueDescription: props.pendingIssueModificationRequest?.nonratingIssueDescription || '',
      removeOriginalIssue: false,
      withdrawalDate: formatDateStr(formatDate(props.pendingIssueModificationRequest?.withdrawalDate),
        'MM/DD/YYYY', 'YYYY-MM-DD') || ''
    },
    mode: 'onChange',
    resolver: yupResolver(props.schema),
    reValidateMode: 'onSubmit' });

  const { handleSubmit, formState } = methods;

  // const onVhaAdminSubmit = (args) => {
  //   dispatch(adminWithdrawRequestIssue(args));
  // };

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
      // ...currentIssueFields,
      ...props.pendingIssueModificationRequest,
      requestIssue: props.pendingIssueModificationRequest?.requestIssue || props.currentIssue,
      ...(props.type === 'addition') && { benefitType },
      requestor: props.pendingIssueModificationRequest?.requestor || { fullName: userFullName, cssId: userCssId },
      decider: userIsVhaAdmin ? { fullName: userFullName, cssId: userCssId } : {},
      requestType: props.type,
      ...issueModificationRequest,
      decisionDate,
      identifier: issueModificationRequest?.identifier || uuid.v4(),
      fromPendingIssues: true
    };

    // close modal and move the issue
    props.onCancel();

    if (userIsVhaAdmin) {
      // TODO:  instead of props.pendingIssueModificationRequest probably we can use something else here
      // TODO: also think about index.

      const index = addedIssues.findIndex(
        (child) => child.id === props.pendingIssueModificationRequest?.requestIssue?.id);

      // dispatch(updatePendingReview(enhancedData));

      switch (props.type) {
      case 'withdrawal':
        dispatch(updatePendingReview(enhancedData));
        dispatch(adminWithdrawRequestIssue(enhancedData, index));
        break;
      case 'removal':
        if (issueModificationRequest.status === 'approve') {
          dispatch(toggleIssueRemoveModal());
          dispatch(updatePendingReview(enhancedData));
        } else {
          dispatch(updatePendingReview(enhancedData));
        }
        break;
      case 'addition':
        if (issueModificationRequest.status === 'approve') {
          dispatch(adminAddRequestIssue(convertPendingIssueToRequestIssue(enhancedData)));
          dispatch(updatePendingReview(enhancedData));
        }
        dispatch(updatePendingReview(enhancedData));
      break;
      case 'modification':
        if (issueModificationRequest.status === 'approve') {
          debugger;
        }
        dispatch(updatePendingReview(enhancedData));
        break;
      default:
        // Do nothing if the dropdown option was not set or implemented.
        break;
      }
    } else {
      if (props.type === 'addition') {
        props.addToPendingReviewSection(enhancedData);
      } else {
        props.moveToPendingReviewSection(enhancedData, props.issueIndex);
      }
    }
  };

  return (
    <div>
      <FormProvider {...methods}>
        <form>
          <Modal
            title={`Request issue ${props.type} request`}
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
