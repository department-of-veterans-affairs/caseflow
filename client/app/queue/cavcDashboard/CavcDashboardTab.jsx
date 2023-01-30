import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';

const CavcDashboardTab = (props) => {
  const { remand } = props;

  return (
    <>
      <div>placeholder for cavc remand details for remand {remand.cavc_docket_number}</div>
      <div>placeholder for issues section</div>
    </>
  );
};

CavcDashboardTab.propTypes = {
  remand: PropTypes.object
};

// const mapStateToProps = (state) => {

// };

// const mapDispatchToProps = (dispatch) => {

// };

export default connect(
  // mapStateToProps,
  null
)(CavcDashboardTab);
