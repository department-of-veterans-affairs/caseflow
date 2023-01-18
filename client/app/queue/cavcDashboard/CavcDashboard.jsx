import React from 'react';
import PropTypes from 'prop-types';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { Redirect } from 'react-router-dom';

export const CavcDashboard = (props) => {
  const { appealId, appeal, appealDetails } = props;

  // cavcRemand is part of appealDetails loaded by the CavcDashboardLoadingScreen. Redirect back
  // to the CaseDetails page if a remand doesn't exist for the provided appealId or if legacy appeal
  if (appealDetails.cavcRemand === null || appeal.isLegacy) {
    return <Redirect to={`/queue/appeals/${appealId}`} />;
  }

  return (
    <React.Fragment>
      <AppSegment filledBackground>
        {/* add future components for display within the AppSegment component */}
        <h1>Cavc Dashboard Placeholder for {appealDetails.appellantFullName}</h1>
      </AppSegment>
    </React.Fragment>
  );
};

CavcDashboard.propTypes = {
  appealId: PropTypes.string.isRequired,
  appeal: PropTypes.object,
  appealDetails: PropTypes.object
};

// mappings and connect are boilerplate for connecting to redux and will be added to in the future
// pass state and ownProps into the function when needed to access them as props
const mapStateToProps = (state, ownProps) => {
  return {
    appeal: state.queue.appeals[ownProps.appealId],
    appealDetails: state.queue.appealDetails[ownProps.appealId]
  };
};

// any actions being used in the component that use/affect the redux store should be mapped here, see
// CaseDetailsLoadingScreen.jsx for example
const mapDispatchToProps = (dispatch) =>
  bindActionCreators(
    {},
    dispatch
  );

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(CavcDashboard);
