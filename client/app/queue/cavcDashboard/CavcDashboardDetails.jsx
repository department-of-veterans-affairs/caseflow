
import React, { useState } from 'react';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import { css } from 'glamor';
import { LABELS } from './cavcDashboardConstants';
import Button from '../../components/Button';
import { PencilIcon } from '../../components/icons/PencilIcon';
import { DateString } from '../../util/DateUtil';
import Modal from '../../components/Modal';
import COPY from '../../../COPY';
import DateSelector from '../../components/DateSelector';
import TextField from '../../components/TextField';
import RadioField from '../../components/RadioField';
import ValidatorsUtil from '../../util/ValidatorsUtil';

const CavcDashboardDetailsContainer = ({ children }) => {
  const containerStyling = css({
    display: 'flex',
    justifyContent: 'space-between',
    '@media(max-width: 829px)': {
      flexDirection: 'column'
    }
  });

  return <div {...containerStyling}>{children}</div>;
};

CavcDashboardDetailsContainer.propTypes = {
  children: PropTypes.node
};

const CavcDashboardDetailsSection = ({ title, value }) => {
  const sectionStyling = css({
    padding: '0 0.5rem 0 0.5rem',
    '& > p': {
      fontWeight: 'bold',
      margin: '0'
    },
  });

  return (
    <div {...sectionStyling}>
      <p>{title}</p>
      <span>{value}</span>
    </div>
  );
};

CavcDashboardDetailsSection.propTypes = {
  title: PropTypes.string,
  value: PropTypes.oneOfType([PropTypes.string, PropTypes.object]),
};

export const CavcDashboardDetails = (props) => {
  const { dashboard, userCanEdit } = props;
  const { validDocketNum, dateValidator } = ValidatorsUtil;
  // states used to display in details section
  const [origBoardDecisionDate, setOrigBoardDecisionDate] = useState(dashboard.board_decision_date);
  const [origBoardDocketNumber, setOrigBoardDocketNumber] = useState(dashboard.board_docket_number);
  const [origCavcDecisionDate, setOrigCavcDecisionDate] = useState(dashboard.cavc_decision_date);
  const [origCavcDocketNumber, setOrigCavcDocketNumber] = useState(dashboard.cavc_docket_number);
  const [origJointMotionForRemand, setOrigJointMotionForRemand] = useState(dashboard.joint_motion_for_remand);
  // states used to display in modal
  const [boardDecisionDate, setBoardDecisionDate] = useState(origBoardDecisionDate);
  const [boardDocketNumber, setBoardDocketNumber] = useState(origBoardDocketNumber);
  const [cavcDecisionDate, setCavcDecisionDate] = useState(origCavcDecisionDate);
  const [cavcDocketNumber, setCavcDocketNumber] = useState(origCavcDocketNumber);
  const [jointMotionForRemand, setJointMotionForRemand] = useState(origJointMotionForRemand);
  const [openDetailsModal, setOpenDetailsModal] = useState(false);

  const openHandler = () => {
    setOpenDetailsModal((current) => (!current));
  };

  const clickHandler = () => {
    // resets modal states back to original details info
    setBoardDecisionDate(origBoardDecisionDate);
    setBoardDocketNumber(origBoardDocketNumber);
    setCavcDecisionDate(origCavcDecisionDate);
    setCavcDocketNumber(origCavcDocketNumber);
    setJointMotionForRemand(origJointMotionForRemand);
    setOpenDetailsModal((current) => (!current));
  };

  const submitHandler = () => {
    // edits details info with modal changes
    setOrigBoardDecisionDate(boardDecisionDate);
    setOrigBoardDocketNumber(boardDocketNumber);
    setOrigCavcDecisionDate(cavcDecisionDate);
    setOrigCavcDocketNumber(cavcDocketNumber);
    setOrigJointMotionForRemand(jointMotionForRemand);
    setOpenDetailsModal((current) => (!current));
  };

  const validCavcDocketNumber = () => (/^\d{2}[-‐−–—]\d{1,5}$/).exec(cavcDocketNumber);

  const validateForm = () => {
    return (
      dateValidator(boardDecisionDate) &&
      validDocketNum(boardDocketNumber) &&
       dateValidator(cavcDecisionDate) &&
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

  // position/top bypasses the fixed margin on the TabWindow component
  const buttonStyling = css({
    position: 'relative',
    top: '-30px',
    margin: '0',
    visibility: (userCanEdit ? 'visible' : 'hidden')
  });

  const modalStyling = css({
    color: '#323a45 !important',
    marginBottom: '1rem !important'
  });

  return (
    <div id={`dashboard-details-${dashboard.id}`}>
      <Button linkStyling willNeverBeLoading classNames={['cf-push-right', 'cf-modal-link']}
        styling={buttonStyling} disabled={!userCanEdit} onClick={openHandler}
      >
        <span {...css({ position: 'absolute' })}><PencilIcon /></span>
        <span {...css({ marginLeft: '20px' })}>Edit</span>
      </Button>
      <CavcDashboardDetailsContainer>
        <CavcDashboardDetailsSection
          title={LABELS.BOARD_DECISION_DATE} value={<DateString date={origBoardDecisionDate} />}
        />
        <CavcDashboardDetailsSection title={LABELS.BOARD_DOCKET_NUMBER} value={origBoardDocketNumber} />
        <CavcDashboardDetailsSection
          title={LABELS.CAVC_DECISION_DATE} value={<DateString date={origCavcDecisionDate} />}
        />
        <CavcDashboardDetailsSection title={LABELS.CAVC_DOCKET_NUMBER} value={origCavcDocketNumber} />
        <CavcDashboardDetailsSection title={LABELS.IS_JMR} value={origJointMotionForRemand ? 'Yes' : 'No'} />
      </CavcDashboardDetailsContainer>
      {openDetailsModal &&
      <Modal title={COPY.CAVC_DASHBOARD_EDIT_DETAILS_MODAL_TITLE}
        buttons={[
          {
            classNames: ['usa-button', 'cf-btn-link'],
            name: COPY.MODAL_CANCEL_BUTTON,
            onClick: clickHandler,
          },
          {
            classNames: ['usa-button'],
            name: COPY.MODAL_SAVE_BUTTON,
            disabled: !validateForm(),
            onClick: submitHandler,
          }
        ]}
        closeHandler={clickHandler}>
        <div {...modalStyling}><DateSelector
          name={LABELS.BOARD_DECISION_DATE}
          type="date"
          onChange={(date) => (setBoardDecisionDate(date))}
          value={boardDecisionDate}
          dateErrorMessage={dateValidator(boardDecisionDate) ? null : COPY.CAVC_DECISION_DATE_ERROR}
          label={LABELS.BOARD_DECISION_DATE}
        />
        </div>
        <div {...modalStyling}><TextField
          name={LABELS.BOARD_DOCKET_NUMBER}
          type="string"
          onChange={(docket) => (setBoardDocketNumber(docket))}
          value={boardDocketNumber}
          errorMessage={validDocketNum(boardDocketNumber) ? null : COPY.BOARD_DOCKET_NUMBER_ERROR}
          label={LABELS.BOARD_DOCKET_NUMBER}
        />
        </div>
        <div {...modalStyling}><DateSelector
          name={LABELS.CAVC_DECISION_DATE}
          type="date"
          onChange={(date) => setCavcDecisionDate(date)}
          value={cavcDecisionDate}
          dateErrorMessage={dateValidator(cavcDecisionDate) ? null : COPY.CAVC_DECISION_DATE_ERROR}
          label={LABELS.CAVC_DECISION_DATE}
        />
        </div>
        <div {...modalStyling}><TextField
          name={LABELS.CAVC_DOCKET_NUMBER}
          type="string"
          onChange={(docket) => (setCavcDocketNumber(docket))}
          value={cavcDocketNumber}
          errorMessage={validCavcDocketNumber() ? null : COPY.CAVC_DOCKET_NUMBER_ERROR}
          label={LABELS.CAVC_DOCKET_NUMBER}
        />
        </div>
        <RadioField
          name={LABELS.IS_JMR}
          value={Boolean(jointMotionForRemand)}
          options={radioOptions}
          onChange={() => {
            setJointMotionForRemand(!jointMotionForRemand);
          }}
        />
      </Modal>}
    </div>
  );
};

CavcDashboardDetails.propTypes = {
  dashboardId: PropTypes.number,
  dashboard: PropTypes.object,
  userCanEdit: PropTypes.bool,
};

const mapStateToProps = (state) => ({
  userCanEdit: state.ui.canEditCavcDashboards
});

export default connect(
  mapStateToProps
)(CavcDashboardDetails);
