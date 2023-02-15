
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
    }
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

  // remove eslint disable when the set methods are used for editing
  /* eslint-disable no-unused-vars */

  const [boardDecisionDate, setBoardDecisionDate] = useState(dashboard.board_decision_date);
  const [boardDocketNumber, setBoardDocketNumber] = useState(dashboard.board_docket_number);
  const [cavcDecisionDate, setCavcDecisionDate] = useState(dashboard.cavc_decision_date);
  const [cavcDocketNumber, setCavcDocketNumber] = useState(dashboard.cavc_docket_number);
  const [jointMotionForRemand, setJointMotionForRemand] = useState(dashboard.joint_motion_for_remand);
  const [openDetailsModal, setOpenDetailsModal] = useState(false);
  /* eslint-enable no-unused-vars */

  const checkIfJmrJmpr = () => {
    switch (remandSubtype) {
    case CAVC_REMAND_SUBTYPES.jmr:
    case CAVC_REMAND_SUBTYPES.jmpr:
    case CAVC_REMAND_SUBTYPES.jmr_jmpr:
      return true;
    default:
      return false;
    }
  };

  const clickHandler = () => {
    setOpenDetailsModal((current) => (!current));
    console.log(openDetailsModal);
  };

  const submitHandler = () => {
    setOpenDetailsModal(false);
    console.log(openDetailsModal);
  };

  const validateForm = () => {
    return (
      boardDecisionDate !== null &&
      boardDocketNumber !== null &&
       cavcDecisionDate !== null &&
        cavcDocketNumber !== null);
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

  return (
    <div id={`dashboard-details-${dashboard.id}`}>
      <Button linkStyling willNeverBeLoading classNames={['cf-push-right', 'cf-modal-link']}
        styling={buttonStyling} disabled={!userCanEdit} onClick={clickHandler}
      >
        <span {...css({ position: 'absolute' })}><PencilIcon /></span>
        <span {...css({ marginLeft: '20px' })}>Edit</span>
      </Button>
      <CavcDashboardDetailsContainer>
        <CavcDashboardDetailsSection
          title={LABELS.BOARD_DECISION_DATE} value={<DateString date={boardDecisionDate} />}
        />
        <CavcDashboardDetailsSection title={LABELS.BOARD_DOCKET_NUMBER} value={boardDocketNumber} />
        <CavcDashboardDetailsSection
          title={LABELS.CAVC_DECISION_DATE} value={<DateString date={cavcDecisionDate} />}
        />
        <CavcDashboardDetailsSection title={LABELS.CAVC_DOCKET_NUMBER} value={cavcDocketNumber} />
        <CavcDashboardDetailsSection title={LABELS.IS_JMR} value={jointMotionForRemand ? 'Yes' : 'No'} />
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
            disabled: !userCanEdit,
            onClick: submitHandler,
          }
        ]}
        closeHandler={clickHandler}>
        <DateSelector
          name={LABELS.BOARD_DECISION_DATE}
          type="date"
          onChange={(date) => (setBoardDecisionDate(date))}
          value={boardDecisionDate}
          label={LABELS.BOARD_DECISION_DATE}
        />
        <TextField
          name={LABELS.BOARD_DOCKET_NUMBER}
          type="string"
          onChange={(docket) => (setBoardDocketNumber(docket))}
          value={boardDocketNumber}
          label={LABELS.BOARD_DOCKET_NUMBER}
        />
        <DateSelector
          name={LABELS.CAVC_DECISION_DATE}
          type="date"
          onChange={(date) => setCavcDecisionDate(date)}
          value={cavcDecisionDate}
          label={LABELS.CAVC_DECISION_DATE}
        />
        <TextField
          name={LABELS.CAVC_DOCKET_NUMBER}
          type="string"
          onChange={(docket) => (setCavcDocketNumber(docket))}
          value={cavcDocketNumber}

          label={LABELS.CAVC_DOCKET_NUMBER} />
        <RadioField
          name={LABELS.IS_JMR}
          value={checkIfJmrJmpr()}
          options={radioOptions}
        />
      </Modal>}
    </div>
  );
};

CavcDashboardDetails.propTypes = {
  dashboardId: PropTypes.number,
  dashboard: PropTypes.object,
  userCanEdit: PropTypes.bool
};

const mapStateToProps = (state) => ({
  userCanEdit: state.ui.canEditCavcDashboards
});

export default connect(
  mapStateToProps
)(CavcDashboardDetails);
