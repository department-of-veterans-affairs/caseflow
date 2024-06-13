import React from 'react';
import PropTypes from 'prop-types';
import { useForm, FormProvider } from 'react-hook-form';
import { yupResolver } from '@hookform/resolvers/yup';
import Modal from 'app/components/Modal';
import { useSelector, useDispatch } from 'react-redux';
import { formatDateStr, formatDate } from '../../../util/DateUtil';
import uuid from 'uuid';
import {
  adminWithdrawRequestIssue,
  updatePendingReview,
  adminAddRequestIssue,
  enhancedPendingReview
} from 'app/intake/actions/issueModificationRequest';
import {
  toggleIssueRemoveModal
} from 'app/intake/actions/addIssues';
import { convertPendingIssueToRequestIssue } from 'app/intake/util/issueModificationRequests';

export const RequestIssueFormWrapper = (props) => {

  const userFullName = useSelector((state) => state.userFullName);
  const userCssId = useSelector((state) => state.userCssId);
  const benefitType = useSelector((state) => state.benefitType);
  const userIsVhaAdmin = useSelector((state) => state.userIsVhaAdmin);

  const dispatch = useDispatch();

  const methods = useForm({
    defaultValues: {
      requestReason: props.pendingIssueModificationRequest?.requestReason || '',
      nonratingIssueCategory: props.pendingIssueModificationRequest?.nonratingIssueCategory || '',
      decisionDate: props.pendingIssueModificationRequest?.decisionDate || '',
      nonratingIssueDescription: props.pendingIssueModificationRequest?.nonratingIssueDescription || '',
      removeOriginalIssue: false,
      withdrawalDate: formatDateStr(formatDate(props.pendingIssueModificationRequest?.withdrawalDate),
        'MM/DD/YYYY', 'YYYY-MM-DD') || '',
      status: 'assigned'
    },
    mode: 'onChange',
    resolver: yupResolver(props.schema),
    reValidateMode: 'onSubmit' });

  const { handleSubmit, formState } = methods;

  const whenAdminApproves = (enhancedData, removeOriginalIssue) => {
    switch (props.type) {
    case 'withdrawal':
      dispatch(updatePendingReview(enhancedData?.identifier, enhancedData));
      dispatch(adminWithdrawRequestIssue(enhancedData?.identifier, enhancedData));
      break;
    case 'removal':
      dispatch(toggleIssueRemoveModal());
      break;
    case 'addition':
      dispatch(updatePendingReview(enhancedData?.identifier, enhancedData));
      dispatch(adminAddRequestIssue(convertPendingIssueToRequestIssue(enhancedData)));
      break;
    case 'modification':
      if (removeOriginalIssue) {
        // dispatch(updatePendingReview(enhancedData?.identifier, enhancedData));
        props.toggleConfirmPendingRequestIssueModal();
      } else {
        const modifiedEnhancedData = { ...enhancedData, requestIssue: {}, requestIssueId: null };

        dispatch(adminAddRequestIssue(convertPendingIssueToRequestIssue(modifiedEnhancedData)));
        dispatch(updatePendingReview(enhancedData?.identifier, enhancedData));
      }
      break;
    default:
      // Do nothing if the dropdown option was not set or implemented.
      break;
    }
  };

  const vhaNonAdmin = (enhancedData) => {
    if (props.type === 'addition') {
      props.addToPendingReviewSection(enhancedData);
    } else {
      props.moveToPendingReviewSection(enhancedData);
    }
  };

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
    const decisionDate = issueModificationRequest.decisionDate ||
      formatDateStr(props.currentIssue.decisionDate);

    const enhancedData = {
      ...currentIssueFields,
      ...props.pendingIssueModificationRequest,
      requestIssue: props.pendingIssueModificationRequest?.requestIssue || props.currentIssue,
      ...(props.type === 'addition') && { benefitType },
      requestor: props.pendingIssueModificationRequest?.requestor || { fullName: userFullName, cssId: userCssId },
      decider: userIsVhaAdmin ? { fullName: userFullName, cssId: userCssId } : {},
      requestType: props.type,
      ...issueModificationRequest,
      decisionDate,
      identifier: props.pendingIssueModificationRequest?.id || uuid.v4(),
      status: issueModificationRequest?.status || 'assigned'
    };

    const status = enhancedData.status;
    const removeOriginalIssue = issueModificationRequest.removeOriginalIssue;

    // close modal and move the issue
    props.onCancel();

    if (userIsVhaAdmin) {
      if (status === 'approve') {
        dispatch(enhancedPendingReview(enhancedData?.identifier, enhancedData));
        whenAdminApproves(enhancedData, removeOriginalIssue);
      } else {
        dispatch(updatePendingReview(enhancedData?.identifier, enhancedData));
      }
    } else {
      vhaNonAdmin(enhancedData);
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
  pendingIssueModificationRequest: PropTypes.object,
  toggleConfirmPendingRequestIssueModal: PropTypes.func
};

export default RequestIssueFormWrapper;
