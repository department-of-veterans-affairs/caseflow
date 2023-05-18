import React, { useState } from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { getCavcDashboardById, getCavcDashboardIndex } from './cavcDashboardSelectors';
import CavcDashboardDetails from './CavcDashboardDetails';
import CavcDashboardIssuesSection from './CavcDashboardIssuesSection';
import Button from '../../components/Button';
import AddCavcDashboardIssueModal from './AddCavcDashboardIssueModal';
import COPY from '../../../COPY';
import { updateDashboardIssues, removeDashboardIssue } from './cavcDashboardActions';
import { bindActionCreators } from 'redux';

export const CavcDashboardTab = (props) => {
  const { userCanEdit, dashboardIndex, dashboardId } = props;
  const [modalIsOpen, setModalIsOpen] = useState(false);
  const [addedIssuesCount, setAddedIssuesCount] = useState(0);

  const closeHandler = () => {
    setModalIsOpen(!modalIsOpen);
  };

  const submitHandler = (issue, dashboardDisposition) => {
    setAddedIssuesCount(addedIssuesCount + 1);
    props.updateDashboardIssues(dashboardIndex, issue, dashboardDisposition);
    setModalIsOpen(!modalIsOpen);
  };

  return (
    <>
      <CavcDashboardDetails {...props} />
      <div><CavcDashboardIssuesSection {...props} /></div>
      {
        (userCanEdit) &&
        <Button
          type="button"
          name="Add Issue Button"
          classNames={['usa-button-secondary']}
          onClick={() => setModalIsOpen(true)}
        >
          { COPY.ADD_CAVC_DASHBOARD_ISSUE_BUTTON_TEXT }
        </Button>
      }
      {
        (modalIsOpen) &&
        <AddCavcDashboardIssueModal
          dashboardId={dashboardId}
          closeHandler={closeHandler}
          submitHandler={submitHandler}
          addedIssuesCount={addedIssuesCount}
        />
      }
    </>
  );
};

CavcDashboardTab.propTypes = {
  dashboardId: PropTypes.number,
  dashboardIndex: PropTypes.number,
  dashboard: PropTypes.object,
  canEditCavcDashboards: PropTypes.bool,
  userCanEdit: PropTypes.bool,
  updateDashboardIssues: PropTypes.func,
  removeDashboardIssue: PropTypes.func
};

const mapStateToProps = (state, ownProps) => {
  return {
    dashboard: getCavcDashboardById(state, { dashboardId: ownProps.dashboardId }),
    dashboardIndex: getCavcDashboardIndex(state, { dashboardId: ownProps.dashboardId })
  };
};

const mapDispatchToProps = (dispatch) =>
  bindActionCreators({
    updateDashboardIssues,
    removeDashboardIssue
  }, dispatch);

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(CavcDashboardTab);
