import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { CavcDashboardIssuesSection } from './CavcDashboardIssuesSection';
import { getCavcRemandById } from './cavcDashboardSelectors';
import CavcDashboardDetails from './CavcDashboardDetails';

export const CavcDashboardTab = (props) => {
  return (
    <>
      <CavcDashboardDetails {...props} />
      <div><CavcDashboardIssuesSection {...props} /></div>
    </>
  );
};

CavcDashboardTab.propTypes = {
  remandId: PropTypes.number,
  remand: PropTypes.object
};

const mapStateToProps = (state, ownProps) => {
  return {
    remand: getCavcRemandById(state, { remandId: ownProps.remandId })
  };
};

// const mapDispatchToProps = (dispatch) => {

// };

export default connect(
  mapStateToProps,
  // mapDispatchToProps
)(CavcDashboardTab);
