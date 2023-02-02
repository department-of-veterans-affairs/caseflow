import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { getCavcRemandById } from './cavcDashboardSelectors';
import CavcDashboardDetails from './CavcDashboardDetails';

export const CavcDashboardTab = (props) => {
  // remand is the serialized CAVC remand for the tab, see cavc_remand_serializer.rb for attrs
  // const { remand, remandId } = props;

  return (
    <>
      <CavcDashboardDetails {...props} />
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
