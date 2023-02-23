import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { getCavcDashboardById } from './cavcDashboardSelectors';
import CavcDashboardDetails from './CavcDashboardDetails';
import CavcDashboardIssuesSection from './CavcDashboardIssuesSection';

export const CavcDashboardTab = (props) => {
  return (
    <>
      <CavcDashboardDetails {...props} />
      <div><CavcDashboardIssuesSection {...props} /></div>
    </>
  );
};

CavcDashboardTab.propTypes = {
  dashboardId: PropTypes.number,
  dashboard: PropTypes.object
};

const mapStateToProps = (state, ownProps) => {
  return {
    dashboard: getCavcDashboardById(state, { dashboardId: ownProps.dashboardId }),
    userCanEdit: state.ui.canEditCavcDashboards
  };
};

// const mapDispatchToProps = (dispatch) => {

// };

export default connect(
  mapStateToProps,
  // mapDispatchToProps
)(CavcDashboardTab);
