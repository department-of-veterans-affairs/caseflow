import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { getCavcRemandById } from './cavcDashboardSelectors';
import CavcDashboardDetails from './CavcDashboardDetails';

export const CavcDashboardTab = (props) => {
  return (
    <>
      <CavcDashboardDetails {...props} />
    </>
  );
};

CavcDashboardTab.propTypes = {
  remandId: PropTypes.number,
  remand: PropTypes.object,
  userOrgs: PropTypes.arrayOf(PropTypes.object)
};

const mapStateToProps = (state, ownProps) => {
  return {
    remand: getCavcRemandById(state, { remandId: ownProps.remandId }),
    userOrgs: state.ui.organizations
  };
};

// const mapDispatchToProps = (dispatch) => {

// };

export default connect(
  mapStateToProps,
  // mapDispatchToProps
)(CavcDashboardTab);
