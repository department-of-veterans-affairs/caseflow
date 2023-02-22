
import React, { useState } from 'react';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import { css } from 'glamor';
import { LABELS } from './cavcDashboardConstants';
import Button from '../../components/Button';
import { PencilIcon } from '../../components/icons/PencilIcon';
import { DateString } from '../../util/DateUtil';

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
  /* eslint-enable no-unused-vars */

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
        styling={buttonStyling} disabled={!userCanEdit} onClick={null}
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
