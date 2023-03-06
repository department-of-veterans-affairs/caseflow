
import React, { useState } from 'react';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import { css } from 'glamor';
import { LABELS } from './cavcDashboardConstants';
import Button from '../../components/Button';
import { PencilIcon } from '../../components/icons/PencilIcon';
import { DateString } from '../../util/DateUtil';
import CavcDashboardEditDetailsModal from './CavcDashboardEditDetailsModal';
import { getCavcDashboardIndex } from './cavcDashboardSelectors';
import { updateDashboardData } from './cavcDashboardActions';
import { bindActionCreators } from 'redux';

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
    '@media(min-width: 830px)': {
      ':first-child': {
        paddingLeft: '0'
      },
      ':last-child': {
        paddingRight: '0'
      }
    },
    '@media(max-width: 829px)': {
      padding: '0'
    },
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
  const { dashboard, userCanEdit, dashboardIndex } = props;
  const [openDetailsModal, setOpenDetailsModal] = useState(false);

  const Details = {
    id: dashboard.id,
    boardDecisionDate: dashboard.board_decision_date,
    boardDocketNumber: dashboard.board_docket_number,
    cavcDecisionDate: dashboard.cavc_decision_date,
    cavcDocketNumber: dashboard.cavc_docket_number,
    jointMotionForRemand: dashboard.joint_motion_for_remand,
  };

  const openHandler = () => {
    setOpenDetailsModal((current) => (!current));
  };

  const closeHandler = () => {
    setOpenDetailsModal((current) => (!current));
  };

  const saveHandler = (updatedData) => {
    props.updateDashboardData(dashboardIndex, updatedData);
    setOpenDetailsModal((current) => (!current));
  };

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
        styling={buttonStyling} disabled={!userCanEdit} onClick={openHandler}
      >
        <span {...css({ position: 'absolute' })}><PencilIcon /></span>
        <span {...css({ marginLeft: '20px' })}>Edit</span>
      </Button>
      <CavcDashboardDetailsContainer>
        <CavcDashboardDetailsSection
          title={LABELS.BOARD_DECISION_DATE} value={<DateString date={dashboard.board_decision_date} />}
        />
        <CavcDashboardDetailsSection title={LABELS.BOARD_DOCKET_NUMBER} value={dashboard.board_docket_number} />
        <CavcDashboardDetailsSection
          title={LABELS.CAVC_DECISION_DATE} value={<DateString date={dashboard.cavc_decision_date} />}
        />
        <CavcDashboardDetailsSection title={LABELS.CAVC_DOCKET_NUMBER} value={dashboard.cavc_docket_number} />
        <CavcDashboardDetailsSection title={LABELS.IS_JMR} value={dashboard.joint_motion_for_remand ? 'Yes' : 'No'} />
      </CavcDashboardDetailsContainer>
      {
        openDetailsModal &&
      <CavcDashboardEditDetailsModal closeHandler={closeHandler} saveHandler={saveHandler} Details={Details} />
      }
    </div>
  );
};

CavcDashboardDetails.propTypes = {
  dashboardId: PropTypes.number,
  dashboard: PropTypes.object,
  userCanEdit: PropTypes.bool,
  updateDashboardData: PropTypes.func,
  dashboardIndex: PropTypes.number,
};

const mapStateToProps = (state, ownProps) => ({
  dashboardIndex: getCavcDashboardIndex(state, { dashboardId: ownProps.dashboardId })
});

const mapDispatchToProps = (dispatch) =>
  bindActionCreators({
    updateDashboardData
  }, dispatch);

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(CavcDashboardDetails);
