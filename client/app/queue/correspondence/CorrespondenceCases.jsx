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
import Button from '../../components/Button';
import RadioField from '../../components/RadioField';
import TextareaField from '../../components/TextareaField';

const CorrespondenceCases = (props) => {
  const dispatch = useDispatch();
  const configUrl = props.configUrl;

  const currentAction = useSelector((state) => state.reviewPackage.lastAction);
  const veteranInformation = useSelector((state) => state.reviewPackage.veteranInformation);

  const [vetName, setVetName] = useState('');
  const [selectedRequestChoice, setSelectedRequestChoice] = useState('');

  useEffect(() => {
    dispatch(loadCorrespondenceConfig(configUrl));
  }, []);

  const config = useSelector((state) => state.intakeCorrespondence.correspondenceConfig);
  const showReassignPackageModal = useSelector((state) => state.intakeCorrespondence.showReassignPackageModal);
  const showRemovePackageModal = useSelector((state) => state.intakeCorrespondence.showRemovePackageModal);

  const actionRequiredOptions = [
    { displayText: 'Approve request', value: 'approve' },
    { displayText: 'Reject request', value: 'reject' }
  ];

  const reviewRequestButtons = [
    {
      classNames: ['cf-modal-link', 'cf-btn-link'],
      name: 'Cancel',
      onClick: () => dispatch(setShowReassignPackageModal(false)),
      disabled: false
    },
    {
      id: '#confirm-button',
      classNames: ['usa-button', 'usa-button-primary', 'cf-margin-left-2rem'],
      name: 'Confirm',
      onClick: () => console.log('confirm clicked'),
      disabled: false
    },
    {
      id: '#view-package-button',
      classNames: ['usa-button', 'usa-button-secondary'],
      name: 'View package',
      onClick: () => console.log('view package clicked'),
      disabled: false
    }
  ];

  const closeReassignPackageModal = () => {
    dispatch(setShowReassignPackageModal(false));
  };

  const closeRemovePackageModal = () => {
    dispatch(setShowRemovePackageModal(false));
  };

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
          isSuperuser={props.isSuperuser}
          isSupervisor={props.isSupervisor} />}
        {showReassignPackageModal &&
        <Modal
          title={COPY.CORRESPONDENCE_CASES_REASSIGN_PACKAGE_MODAL_TITLE}
          closeHandler={closeReassignPackageModal}
          buttons={reviewRequestButtons}
        >
          <b>Reason for removal:</b>
          <p>PLACEHOLDER USER JUSTIFICATION</p>
          <div>
            <RadioField
              name="actionRequiredRadioField"
              label="Choose whether to approve the request for removal or reject it."
              options={actionRequiredOptions}
              onChange={(val) => setSelectedRequestChoice(val)}
              value={selectedRequestChoice}
              optionsStyling={{ width: '180px' }}
            />
          </div>
          {selectedRequestChoice === 'reject' &&
          <TextareaField name="Provide a reason for rejection" />}
        </Modal>}
        {showRemovePackageModal &&
        <Modal
          title={COPY.CORRESPONDENCE_CASES_REMOVE_PACKAGE_MODAL_TITLE}
          closeHandler={closeRemovePackageModal}
          cancelButton={<Button linkStyling onClick={closeRemovePackageModal}>Cancel</Button>}
        />}
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
  isSuperuser: PropTypes.bool,
  isSupervisor: PropTypes.bool

};

export default CorrespondenceCases;
