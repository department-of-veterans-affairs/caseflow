import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { Redirect } from 'react-router-dom';
import { fetchAppealDetails } from '../QueueActions';
import LoadingScreen from '../../components/LoadingScreen';
import { LOGO_COLORS } from '../../constants/AppConstants';
import COPY from '../../../COPY';
import StatusMessage from '../../components/StatusMessage';

export const CavcDashboard = (props) => {
  const { appealId, appeal, appealDetails } = props;

  const [loaded, setLoaded] = useState(false);
  const [error, setError] = useState();

  useEffect(() => {
    props.fetchAppealDetails(appealId).
      catch(() => setError(true)).
      finally(() => setLoaded(true));
  }, []);

  // cavcRemand is part of appealDetails loaded by the CavcDashboardLoadingScreen. Redirect back
  // to the CaseDetails page if a remand doesn't exist for the provided appealId or if legacy appeal
  if (loaded && (appealDetails.cavcRemand === null || appeal.isLegacy)) {
    return <Redirect to={`/queue/appeals/${appealId}`} />;
  }

  return (
    <React.Fragment>
      <AppSegment filledBackground>
        {!loaded &&
          <LoadingScreen
            spinnerColor={LOGO_COLORS.QUEUE.ACCENT}
            message={COPY.CAVC_DASHBOARD_LOADING_SCREEN_TEXT}
          />}
        {loaded && !error &&
          <h1>CAVC appeals for {appealDetails?.appellantFullName}</h1>

          /* add future components for dashboard display within this conditional render */
        }
        {loaded && error &&
          <StatusMessage
            title={COPY.CAVC_DASHBOARD_LOADING_FAILURE_TITLE}
            messageText={COPY.CAVC_DASHBOARD_LOADING_FAILURE_TEXT}
          />}
      </AppSegment>
    </React.Fragment>
  );
};

CavcDashboard.propTypes = {
  appealId: PropTypes.string.isRequired,
  appeal: PropTypes.object,
  appealDetails: PropTypes.object,
  fetchAppealDetails: PropTypes.func
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
  bindActionCreators({
    fetchAppealDetails
  }, dispatch);

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(CavcDashboard);
