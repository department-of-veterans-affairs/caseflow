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
import ApiUtil from '../../util/ApiUtil';
import { sprintf } from 'sprintf-js';
import CorrespondenceTableBuilder from './CorrespondenceTableBuilder';
import Alert from '../../components/Alert';
import Modal from 'app/components/Modal';
import RadioFieldWithChildren from '../../components/RadioFieldWithChildren';
import ReactSelectDropdown from '../../components/ReactSelectDropdown';
import TextareaField from '../../components/TextareaField';
import AutoAssignAlertBanner from '../correspondence/component/AutoAssignAlertBanner';
import { css } from 'glamor';
import WindowUtil from '../../util/WindowUtil';

const CorrespondenceCases = (props) => {
  const dispatch = useDispatch();
  const configUrl = props.configUrl || '/queue/correspondence?json';

  const currentAction = useSelector((state) => state.reviewPackage.lastAction);

  const vetName = useSelector(
    (state) => state.reviewPackage.correspondence.veteranFullName
  );

  const currentSelectedVeteran = useSelector((state) => state.intakeCorrespondence.selectedVeteranDetails);
  const reassignModalVisible = useSelector((state) => state.intakeCorrespondence.showReassignPackageModal);

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

  const styles = {
    optSelect: css({
      '.reassign': {
      },
      '& .css-yk16xz-control, .css-1pahdxg-control': {
        borderRadius: '0px',
        fontSize: '17px'
      }
    })
  };

  const packageActionMessage = () => {
    switch (currentAction.action_type) {
    case 'removePackage':
      return sprintf(COPY.CORRESPONDENCE_TITLE_REMOVE_PACKAGE_MESSAGE, vetName);
    case 'splitPackage':
      return sprintf(COPY.CORRESPONDENCE_TITLE_SPLIT_PACKAGE_MESSAGE, vetName);
    case 'mergePackage':
      return sprintf(COPY.CORRESPONDENCE_TITLE_MERGE_PACKAGE_MESSAGE, vetName);
    case 'reassignPackage':
      return sprintf(COPY.CORRESPONDENCE_TITLE_REASSIGNMENT_PACKAGE_MESSAGE, vetName);
    default:
    }
  };

  const approveElement = (
    <div className="styling-for-approve-element-assign-to-person">
      <ReactSelectDropdown
        // className="cf-margin-left-2rem img"
        className = {`cf-margin-left-2rem img reassign ${styles.optSelect}`}
        label="Assign to person"
        onChangeMethod={(val) => setSelectedMailTeamUser(val.value)}
        options={buildMailUserData(props.inboundOpsTeamNonAdmin)}
      />
    </div>);

  const textAreaElement = (
    <div className="styling-for-text-area-reason-for-rejection">
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
  const handleConfirmReassignRemoveClick = (actionType) => {
    try {
      const data = {
        action_type: actionType,
        new_assignee: selectedMailTeamUser,
        decision: selectedRequestChoice,
        decision_reason: decisionReason,
      };

      ApiUtil.patch(`/queue/correspondence/tasks/${currentSelectedVeteran.uniqueId}/update`, { data }).
        then(() => {
          WindowUtil.reloadPage();
        });

    } catch (error) {
      console.error(error);
    }
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
        {props.featureToggles.correspondence_queue && <AutoAssignAlertBanner />}
        {(vetName) &&
          currentAction.action_type === 'DeleteReviewPackage' && (
          <Alert
            type="success"
            title={sprintf(COPY.CORRESPONDENCE_TITLE_REMOVE_PACKAGE_BANNER, vetName)}
            message={COPY.CORRESPONDENCE_MESSAGE_REMOVE_PACKAGE_BANNER}
            scrollOnAlert={false}
          />
        )}
        {['splitPackage', 'removePackage', 'reassignPackage', 'mergePackage'].includes(currentAction.action_type) && (
          <Alert
            type="success"
            title={packageActionMessage()}
            message={COPY.CORRESPONDENCE_PACKAGE_ACTION_DESCRIPTION}
            scrollOnAlert={false}
          />
        )}
        {config &&
        <CorrespondenceTableBuilder
          inboundOpsTeamUsers={props.inboundOpsTeamUsers}
          inboundOpsTeamNonAdmin={props.inboundOpsTeamNonAdmin}
          isInboundOpsTeamUser={props.isInboundOpsTeamUser}
          isInboundOpsSuperuser={props.isInboundOpsSuperuser}
          isInboundOpsSupervisor={props.isInboundOpsSupervisor} />}
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
              className={['radio-field-styling-for-reassignment']}
              id="vertical-radio"
              label="Choose whether to approve the request for removal or reject it."
              options={reassignOptions}
              onChange={(val) => setSelectedRequestChoice(val)}
              value={selectedRequestChoice}
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
            className={['radio-field-styling-for-removal']}
            label="Choose whether to approve the request for removal or reject it."
            options={removeOptions}
            onChange={(val) => setSelectedRequestChoice(val)}
            value={selectedRequestChoice}
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
  configUrl: PropTypes.string,
  inboundOpsTeamUsers: PropTypes.arrayOf(string),
  inboundOpsTeamNonAdmin: PropTypes.arrayOf(string),
  responseType: PropTypes.string,
  responseHeader: PropTypes.string,
  responseMessage: PropTypes.string,
  taskIds: PropTypes.array,
  isInboundOpsTeamUser: PropTypes.bool,
  isInboundOpsSuperuser: PropTypes.bool,
  isInboundOpsSupervisor: PropTypes.bool,
  featureToggles: PropTypes.object
};

export default CorrespondenceCases;
