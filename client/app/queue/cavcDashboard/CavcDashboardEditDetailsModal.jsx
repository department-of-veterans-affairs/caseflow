import React, { useState } from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';
import { LABELS } from './cavcDashboardConstants';
import Modal from '../../components/Modal';
import COPY from '../../../COPY';
import DateSelector from '../../components/DateSelector';
import TextField from '../../components/TextField';
import RadioField from '../../components/RadioField';
import ValidatorsUtil from '../../util/ValidatorsUtil';

const CavcDashboardEditDetailsModal = ({ closeHandler, saveHandler, Details }) => {
  const { validDocketNum, dateValidator, futureDate } = ValidatorsUtil;

  const [boardDecisionDate, setBoardDecisionDate] = useState(Details.boardDecisionDate);
  const [boardDocketNumber, setBoardDocketNumber] = useState(Details.boardDocketNumber);
  const [cavcDecisionDate, setCavcDecisionDate] = useState(Details.cavcDecisionDate);
  const [cavcDocketNumber, setCavcDocketNumber] = useState(Details.cavcDocketNumber);
  const [jointMotionForRemand, setJointMotionForRemand] = useState(Details.jointMotionForRemand);

  const updatedData = {
    id: Details.id,
    boardDecisionDateUpdate: boardDecisionDate,
    boardDocketNumberUpdate: boardDocketNumber,
    cavcDecisionDateUpdate: cavcDecisionDate,
    cavcDocketNumberUpdate: cavcDocketNumber,
    jointMotionForRemandUpdate: jointMotionForRemand
  };

  const saveChanges = () => {
    saveHandler(updatedData);
  };

  const validCavcDocketNumber = () => (/^\d{2}[-‐−–—]\d{1,5}$/).exec(cavcDocketNumber);

  const validateForm = () => {
    return (
      dateValidator(boardDecisionDate) && !futureDate(boardDecisionDate) &&
      validDocketNum(boardDocketNumber) &&
       dateValidator(cavcDecisionDate) && !futureDate(cavcDecisionDate) &&
        validCavcDocketNumber());
  };

  const radioOptions = [
    {
      displayText: 'Yes',
      value: true,
    },
    {
      displayText: 'No',
      value: false,
    }];

  const modalStyling = css({
    color: '#323a45 !important',
    marginBottom: '1rem !important'
  });

  const boardDecisionDateField = <DateSelector
    name={LABELS.BOARD_DECISION_DATE}
    type="date"
    onChange={(date) => (setBoardDecisionDate(date))}
    value={boardDecisionDate}
    label={LABELS.BOARD_DECISION_DATE}
    noFutureDates
  />;

  const boardDocketNumberField = <TextField
    name={LABELS.BOARD_DOCKET_NUMBER}
    type="string"
    onChange={(docket) => (setBoardDocketNumber(docket))}
    value={boardDocketNumber}
    errorMessage={validDocketNum(boardDocketNumber) ? null : COPY.BOARD_DOCKET_NUMBER_ERROR}
    label={LABELS.BOARD_DOCKET_NUMBER}
  />;

  const cavcDecisionDateField = <DateSelector
    name={LABELS.CAVC_DECISION_DATE}
    type="date"
    onChange={(date) => setCavcDecisionDate(date)}
    value={cavcDecisionDate}
    label={LABELS.CAVC_DECISION_DATE}
    noFutureDates
  />;

  const cavcDocketNumberField = <TextField
    name={LABELS.CAVC_DOCKET_NUMBER}
    type="string"
    onChange={(docket) => (setCavcDocketNumber(docket))}
    value={cavcDocketNumber}
    errorMessage={validCavcDocketNumber() ? null : COPY.CAVC_DOCKET_NUMBER_ERROR}
    label={LABELS.CAVC_DOCKET_NUMBER}
  />;

  const jointMotionForRemandField = <RadioField
    name={LABELS.IS_JMR}
    value={Boolean(jointMotionForRemand)}
    options={radioOptions}
    onChange={() => {
      setJointMotionForRemand(!jointMotionForRemand);
    }}
  />;

  return (
    <Modal title={COPY.CAVC_DASHBOARD_EDIT_DETAILS_MODAL_TITLE}
      buttons={[
        {
          classNames: ['usa-button', 'cf-btn-link'],
          name: COPY.MODAL_CANCEL_BUTTON,
          onClick: closeHandler,
        },
        {
          classNames: ['usa-button'],
          name: COPY.MODAL_SAVE_BUTTON,
          onClick: saveChanges,
          disabled: !validateForm(),
        }
      ]}
      closeHandler={closeHandler}>
      <div {...modalStyling}>
        {boardDecisionDateField}
      </div>
      <div {...modalStyling}>
        {boardDocketNumberField}
      </div>
      <div {...modalStyling}>
        {cavcDecisionDateField}
      </div>
      <div {...modalStyling}>
        {cavcDocketNumberField}
      </div>
      {jointMotionForRemandField}
    </Modal>
  );
};

CavcDashboardEditDetailsModal.propTypes = {
  closeHandler: PropTypes.func,
  saveHandler: PropTypes.func,
  Details: PropTypes.shape({
    id: PropTypes.number,
    boardDecisionDate: PropTypes.string,
    boardDocketNumber: PropTypes.string,
    cavcDecisionDate: PropTypes.string,
    cavcDocketNumber: PropTypes.string,
    jointMotionForRemand: PropTypes.bool
  })
};

export default CavcDashboardEditDetailsModal;
