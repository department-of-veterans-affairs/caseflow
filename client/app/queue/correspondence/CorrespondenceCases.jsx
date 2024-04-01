import React, { useState, useEffect } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import {
  loadCorrespondenceConfig,
  setShowReassignPackageModal,
  setShowRemovePackageModal
} from './correspondenceReducer/correspondenceActions';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import PropTypes, { string } from 'prop-types';
import COPY from '../../../COPY';
import { sprintf } from 'sprintf-js';
import CorrespondenceTableBuilder from './CorrespondenceTableBuilder';
import Alert from '../../components/Alert';
import Modal from 'app/components/Modal';
import RadioFieldWithChildren from '../../components/RadioFieldWithChildren';
import ReactSelectDropdown from '../../components/ReactSelectDropdown';
import TextareaField from '../../components/TextareaField';

const CorrespondenceCases = (props) => {
  const dispatch = useDispatch();
  const configUrl = props.configUrl;

  const currentAction = useSelector((state) => state.reviewPackage.lastAction);
  const veteranInformation = useSelector((state) => state.reviewPackage.veteranInformation);
  const currentSelectedVeteran = useSelector((state) => state.intakeCorrespondence.selectedVeteranDetails);
  const reassignModalVisible = useSelector((state) => state.intakeCorrespondence.showReassignPackageModal);

  const [vetName, setVetName] = useState('');
  const [selectedMailTeamUser, setSelectedMailTeamUser] = useState('');
  const [selectedRequestChoice, setSelectedRequestChoice] = useState('');
  const [decisionReason, setDecisionReason] = useState('');

  const buildMailUserData = (data) => {

    if (typeof data === 'undefined') {
      return [];
    }

    return data.map((user) => {
      return {
        value: user,
        label: user
      };
    });
  };

  const handleDecisionReasonInput = (value) => {
    setDecisionReason(value);
  };

  const handleViewPackage = () => {
    let url = window.location.href;
    const index = url.indexOf('/team');

    url = url.slice(0, index);
    const parentUrlArray = (currentSelectedVeteran.parentTaskUrl.split('/'));

    window.location.href = (`${url }/${parentUrlArray[3]}/${parentUrlArray[4]}`);
  };

  const resetState = () => {
    setSelectedMailTeamUser('');
    setSelectedRequestChoice('');
    setDecisionReason('');
  };

  const handleReassignClose = () => {
    resetState();
    dispatch(setShowReassignPackageModal(false));
  };

  const handleRemoveClose = () => {
    resetState();
    dispatch(setShowRemovePackageModal(false));
  };

  const confirmButtonDisabled = () => {
    if (selectedRequestChoice === 'approve' && selectedMailTeamUser === '' && reassignModalVisible) {
      return true;
    }

    if (selectedRequestChoice === 'reject' && decisionReason === '') {
      return true;
    }

    if (selectedRequestChoice === '') {
      return true;
    }

    return false;
  };

  const approveElement = (
    <div style={{ width: '250%' }}>
      <ReactSelectDropdown
        className="cf-margin-left-2rem img"
        label="Assign to person"
        onChangeMethod={(val) => setSelectedMailTeamUser(val.value)}
        options={buildMailUserData(props.mailTeamUsers)}
      />
    </div>);

  const textAreaElement = (
    <div style={{ width: '280%' }}>
      <TextareaField label="Provide a reason for rejection"
        onChange={handleDecisionReasonInput}
        value={decisionReason} />
    </div>);

  useEffect(() => {
    dispatch(loadCorrespondenceConfig(configUrl));
  }, []);

  const config = useSelector((state) => state.intakeCorrespondence.correspondenceConfig);
  const showReassignPackageModal = useSelector((state) => state.intakeCorrespondence.showReassignPackageModal);
  const showRemovePackageModal = useSelector((state) => state.intakeCorrespondence.showRemovePackageModal);

  const reassignOptions = [
    { displayText: 'Approve request',
      value: 'approve',
      element: approveElement,
      displayElement: selectedRequestChoice === 'approve'
    },
    { displayText: 'Reject request',
      value: 'reject',
      element: textAreaElement,
      displayElement: selectedRequestChoice === 'reject'
    }
  ];

  const removeOptions = [
    { displayText: 'Approve request',
      value: 'approve',
      displayElement: selectedRequestChoice === 'approve'
    },
    { displayText: 'Reject request',
      value: 'reject',
      element: textAreaElement,
      displayElement: selectedRequestChoice === 'reject'
    }
  ];
  const handleConfirmReassignRemoveClick = (operation) => {
    const newUrl = new URL(window.location.href);
    const searchParams = new URLSearchParams(newUrl.search);
    // Encode and set the query parameters

    searchParams.set('user', encodeURIComponent(selectedMailTeamUser));
    searchParams.set('taskId', encodeURIComponent(currentSelectedVeteran.uniqueId));
    searchParams.set('veteranName', encodeURIComponent(currentSelectedVeteran.veteranDetails.split('(')[0].trim()));
    searchParams.set('userAction', encodeURIComponent(selectedRequestChoice));
    searchParams.set('decisionReason', encodeURIComponent(decisionReason));
    searchParams.set('operation', encodeURIComponent(operation));
    searchParams.set('tab', encodeURIComponent('correspondence_unassigned'));
    searchParams.set('page', encodeURIComponent('1'));

    // Construct the new URL with encoded query parameters
    newUrl.search = searchParams.toString();
    window.location.href = newUrl.href;
  };

  const reassignModalButtons = [
    {
      classNames: ['cf-modal-link', 'cf-btn-link'],
      name: 'Cancel',
      onClick: handleReassignClose,
      disabled: false
    },
    {
      id: '#confirm-button',
      classNames: ['usa-button', 'usa-button-primary', 'cf-margin-left-2rem'],
      name: 'Confirm',
      onClick: () => handleConfirmReassignRemoveClick('reassign'),
      disabled: confirmButtonDisabled()
    },
    {
      id: '#view-package-button',
      classNames: ['usa-button', 'usa-button-secondary'],
      name: 'View package',
      onClick: handleViewPackage,
      disabled: false
    }
  ];

  const removeModalButtons = [
    {
      classNames: ['cf-modal-link', 'cf-btn-link'],
      name: 'Cancel',
      onClick: handleRemoveClose,
      disabled: false
    },
    {
      id: '#confirm-button',
      classNames: ['usa-button', 'usa-button-primary', 'cf-margin-left-2rem'],
      name: 'Confirm',
      onClick: () => handleConfirmReassignRemoveClick('remove'),
      disabled: confirmButtonDisabled()
    },
    {
      id: '#view-package-button',
      classNames: ['usa-button', 'usa-button-secondary'],
      name: 'View package',
      onClick: handleViewPackage,
      disabled: false
    }
  ];

  useEffect(() => {
    if (
      veteranInformation?.veteranName?.firstName &&
      veteranInformation?.veteranName?.lastName
    ) {
      setVetName(
        `${veteranInformation.veteranName.firstName.trim()} ${veteranInformation.veteranName.lastName.trim()}`);
    }
  }, [veteranInformation]);

  return (
    <>
      {props.responseType && (
        <Alert
          type={props.responseType}
          title={props.responseHeader}
          message={props.responseMessage}
          scrollOnAlert={false}
        />
      )}
      <AppSegment filledBackground>
        {(veteranInformation?.veteranName?.firstName && veteranInformation?.veteranName?.lastName) &&
          currentAction.action_type === 'DeleteReviewPackage' && (
          <Alert
            type="success"
            title={sprintf(COPY.CORRESPONDENCE_TITLE_REMOVE_PACKAGE_BANNER, vetName)}
            message={COPY.CORRESPONDENCE_MESSAGE_REMOVE_PACKAGE_BANNER}
            scrollOnAlert={false}
          />
        )}
        {config &&
        <CorrespondenceTableBuilder
          mailTeamUsers={props.mailTeamUsers}
          isMailTeamUser={props.isMailTeamUser}
          isMailSuperUser={props.isMailSuperUser}
          isMailSupervisor={props.isMailSupervisor} />}
        {showReassignPackageModal &&
        <Modal
          closeHandler={handleReassignClose}
          buttons={reassignModalButtons}
          title={COPY.CORRESPONDENCE_CASES_REASSIGN_PACKAGE_MODAL_TITLE}
        >
          <b>Reason for reassignment:</b>
          <p>{currentSelectedVeteran.instructions}</p>
          <div>
            <RadioFieldWithChildren
              name="actionRequiredRadioField"
              id="vertical-radio"
              label="Choose whether to approve the request for removal or reject it."
              options={reassignOptions}
              onChange={(val) => setSelectedRequestChoice(val)}
              value={selectedRequestChoice}
              optionsStyling={{ width: '180px' }}
            />
          </div>
        </Modal>}
        {showRemovePackageModal &&
        <Modal
          title={COPY.CORRESPONDENCE_CASES_REMOVE_PACKAGE_MODAL_TITLE}
          buttons={removeModalButtons}
          closeHandler={handleRemoveClose}>
          <b>Reason for removal:</b>
          <p>{currentSelectedVeteran.instructions}</p>
          <RadioFieldWithChildren
            name="actionRequiredRadioField"
            id="vertical-radio"
            label="Choose whether to approve the request for removal or reject it."
            options={removeOptions}
            onChange={(val) => setSelectedRequestChoice(val)}
            value={selectedRequestChoice}
            optionsStyling={{ width: '180px' }}
          />
        </Modal>}
      </AppSegment>
    </>
  );
};

CorrespondenceCases.propTypes = {
  organizations: PropTypes.array,
  loadCorrespondenceConfig: PropTypes.func,
  correspondenceConfig: PropTypes.object,
  currentAction: PropTypes.object,
  veteranInformation: PropTypes.object,
  configUrl: PropTypes.string,
  mailTeamUsers: PropTypes.arrayOf(string),
  responseType: PropTypes.string,
  responseHeader: PropTypes.string,
  responseMessage: PropTypes.string,
  taskIds: PropTypes.array,
  isMailTeamUser: PropTypes.bool,
  isMailSuperUser: PropTypes.bool,
  isMailSupervisor: PropTypes.bool

};

export default CorrespondenceCases;
