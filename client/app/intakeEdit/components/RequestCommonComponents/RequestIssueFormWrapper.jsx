import React from 'react';
import PropTypes from 'prop-types';
import { useForm, FormProvider } from 'react-hook-form';
import { yupResolver } from '@hookform/resolvers/yup';
import Modal from 'app/components/Modal';
<<<<<<< HEAD
=======
import { useSelector, useDispatch } from 'react-redux';
>>>>>>> pamatya/APPEALS-40997-v3
import { formatDateStr, formatDate, formatDateStringForApi } from '../../../util/DateUtil';
import uuid from 'uuid';
import { isEmpty } from 'lodash';
import { useSelector, useDispatch } from 'react-redux';
import {
  issueWithdrawalRequestApproved,
  updatePendingReview,
  issueAdditionRequestApproved,
  updateActiveIssueModificationRequest
} from 'app/intake/actions/issueModificationRequest';
import {
  toggleIssueRemoveModal
  , setIssueWithdrawalDate } from 'app/intake/actions/addIssues';
import { convertPendingIssueToRequestIssue } from 'app/intake/util/issueModificationRequests';

export const RequestIssueFormWrapper = (props) => {
<<<<<<< HEAD
=======
  const pendingIssueModificationRequest = props.pendingIssueModificationRequest ?
    { ...props.pendingIssueModificationRequest } : {};
>>>>>>> pamatya/APPEALS-40997-v3
  const userFullName = useSelector((state) => state.userFullName);
  const userCssId = useSelector((state) => state.userCssId);
  const benefitType = useSelector((state) => state.benefitType);
  const userIsVhaAdmin = useSelector((state) => state.userIsVhaAdmin);
<<<<<<< HEAD
  const isNewModificationRequest = isEmpty(props.pendingIssueModificationRequest);
=======
  const isNewModificationRequest = Object.entries(props.pendingIssueModificationRequest).length === 0;
>>>>>>> pamatya/APPEALS-40997-v3

  const dispatch = useDispatch();

  const methods = useForm({
    defaultValues: {
      requestReason: pendingIssueModificationRequest.requestReason || '',
      nonratingIssueCategory: pendingIssueModificationRequest.nonratingIssueCategory || '',
      decisionDate: pendingIssueModificationRequest.decisionDate || '',
      nonratingIssueDescription: pendingIssueModificationRequest.nonratingIssueDescription || '',
      removeOriginalIssue: false,
<<<<<<< HEAD
      withdrawalDate: props.pendingIssueModificationRequest?.withdrawalDate || '',
      // withdrawalDate: formatDateStr(formatDate(props.pendingIssueModificationRequest?.withdrawalDate), 'MM/DD/YYYY', 'YYYY-MM-DD') || '',
=======
      withdrawalDate: formatDateStr(formatDate(pendingIssueModificationRequest.withdrawalDate),
        'MM/DD/YYYY', 'YYYY-MM-DD') || '',
>>>>>>> pamatya/APPEALS-40997-v3
      status: 'assigned',
      // TODO: Do you need this since it's not a form field?
      addedFromApprovedRequest: false
    },
    mode: 'onChange',
    resolver: yupResolver(props.schema),
    reValidateMode: 'onSubmit' });

  const { handleSubmit, formState } = methods;

  const whenAdminApproves = (enhancedData, removeOriginalIssue) => {
    if (['withdrawal', 'addition'].includes(props.type)) {
      dispatch(updatePendingReview(enhancedData?.identifier, enhancedData));
    } else {
      dispatch(updateActiveIssueModificationRequest(enhancedData));
    }

    switch (props.type) {
    case 'withdrawal':
      dispatch(issueWithdrawalRequestApproved(enhancedData?.identifier, enhancedData));
      // TODO: This needs to somehow do the logic from add issues in here or in a reducer.
      // So probably need a new action/reducer to do it
      dispatch(setIssueWithdrawalDate(enhancedData.withdrawalDate));
      break;
    case 'removal':
      dispatch(toggleIssueRemoveModal());
      break;
    case 'addition':
      dispatch(issueAdditionRequestApproved(convertPendingIssueToRequestIssue(enhancedData)));
      break;
    case 'modification':
      if (removeOriginalIssue) {
        props.toggleConfirmPendingRequestIssueModal();
      } else {
        const modifiedEnhancedData = { ...enhancedData, requestIssue: {}, requestIssueId: null };

        dispatch(updatePendingReview(modifiedEnhancedData?.identifier, modifiedEnhancedData));
        dispatch(issueAdditionRequestApproved(convertPendingIssueToRequestIssue(modifiedEnhancedData)));
      }
      break;
    default:
      // Do nothing if the dropdown option was not set or implemented.
      break;
    }
  };

  const vhaNonAdmin = (enhancedData) => {
    if (isNewModificationRequest) {
      if (props.type === 'addition') {
        props.addToPendingReviewSection(enhancedData);
      } else {
        props.moveToPendingReviewSection(enhancedData);
      }
    } else {
      props.updatePendingReview(enhancedData.identifier, enhancedData);
    }
  };

  const onSubmit = (issueModificationRequestFormData) => {
    const currentIssueFields = props.currentIssue ?
      {
        requestIssueId: props.currentIssue.id,
        nonratingIssueCategory: props.currentIssue.category,
        nonratingIssueDescription: props.currentIssue.nonRatingIssueDescription,
        benefitType: props.currentIssue.benefitType,
        decisionDate: props.currentIssue.decisionDate
      } : {};

    // The decision date will come from the current issue for removal and withdrawal requests.
    // Ensure date is in a serializable format for redux
<<<<<<< HEAD
    // TODO: Make sure this works for all cases. Hopefully it does.
    const decisionDate = issueModificationRequestFormData.decisionDate ?
      formatDateStringForApi(issueModificationRequestFormData.decisionDate) :
      currentIssueFields.decisionDate;

    const withdrawalDate = issueModificationRequestFormData.withdrawalDate ?
      formatDateStringForApi(issueModificationRequestFormData.withdrawalDate) :
      '';

    // console.log('');
    // console.log('form data withdrawal date: ', issueModificationRequestFormData.withdrawalDate);
    // console.log('formatted withdrawal date:', withdrawalDate);

    // console.log('in form wrapper');
    // console.log('formatted decision date', decisionDate);
    // console.log('form data decision date: ', issueModificationRequestFormData.decisionDate);
    // console.log('when it is formatted:', formatDateStringForApi(issueModificationRequestFormData.decisionDate));
    // console.log('currentIssue decision date', props.currentIssue?.decisionDate);
    // console.log('when it is formatted:', formatDateStringForApi(currentIssueFields.decisionDate));
=======
    const decisionDate = formatDateStringForApi(issueModificationRequest.decisionDate) ||
        formatDateStringForApi(props.currentIssue?.decisionDate);
>>>>>>> pamatya/APPEALS-40997-v3

    const enhancedData = {
      ...currentIssueFields,
      ...props.pendingIssueModificationRequest,
      ...issueModificationRequestFormData,
      requestIssue: props.pendingIssueModificationRequest?.requestIssue || props.currentIssue,
      ...(props.type === 'addition') && { benefitType },
      requestor: props.pendingIssueModificationRequest?.requestor || { fullName: userFullName, cssId: userCssId },
      decider: userIsVhaAdmin ? { fullName: userFullName, cssId: userCssId } : {},
      requestType: props.type,
      decisionDate,
      withdrawalDate,
      identifier: props.pendingIssueModificationRequest?.identifier || uuid.v4(),
      // TODO: This isn't good enough.
      ...(!isNewModificationRequest && !userIsVhaAdmin) && { edited: true },
      status: issueModificationRequestFormData.status || 'assigned',
      // TODO: Do you have to set this here?
      addedFromApprovedRequest: false
    };

    const status = issueModificationRequestFormData.status;
    const removeOriginalIssue = issueModificationRequestFormData.removeOriginalIssue;

    // close modal and move the issue
    props.onCancel();

    if (userIsVhaAdmin) {
      if (status === 'approved') {
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
            title={isNewModificationRequest || userIsVhaAdmin ? `Request issue ${props.type}` : 'Edit pending request'}
            buttons={[
              { classNames: ['cf-modal-link', 'cf-btn-link', 'close-modal'],
                name: 'Cancel',
                onClick: props.onCancel
              },
              {
                classNames: ['usa-button', 'usa-button-primary'],
                name: userIsVhaAdmin ? 'Confirm' : 'Submit request',
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
  toggleConfirmPendingRequestIssueModal: PropTypes.func,
  updatePendingReview: PropTypes.func,
};

export default RequestIssueFormWrapper;
