import React, { useState, useEffect } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import {
  loadCorrespondenceConfig,
  setShowReassignPackageModal,
  setShowRemovePackageModal
} from './correspondenceReducer/correspondenceActions';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import PropTypes from 'prop-types';
import COPY from '../../../COPY';
import { sprintf } from 'sprintf-js';
import CorrespondenceTableBuilder from './CorrespondenceTableBuilder';
import Alert from '../../components/Alert';
import Modal from 'app/components/Modal';
import Button from '../../components/Button';

const CorrespondenceCases = (props) => {
  const dispatch = useDispatch();
  const configUrl = props.configUrl;

  const currentAction = useSelector((state) => state.reviewPackage.lastAction);
  const veteranInformation = useSelector((state) => state.reviewPackage.veteranInformation);

  const [vetName, setVetName] = useState('');

  useEffect(() => {
    dispatch(loadCorrespondenceConfig(configUrl));
  }, []);

  const config = useSelector((state) => state.intakeCorrespondence.correspondenceConfig);
  const showReassignPackageModal = useSelector((state) => state.intakeCorrespondence.showReassignPackageModal);
  const showRemovePackageModal = useSelector((state) => state.intakeCorrespondence.showRemovePackageModal);

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
        <CorrespondenceTableBuilder />}
        {showReassignPackageModal &&
        <Modal
          title={COPY.CORRESPONDENCE_CASES_REASSIGN_PACKAGE_MODAL_TITLE}
          closeHandler={closeReassignPackageModal}
          cancelButton={<Button linkStyling onClick={closeReassignPackageModal}>Cancel</Button>}
        />}
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
  configUrl: PropTypes.string
};

export default CorrespondenceCases;
