import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { Redirect } from 'react-router-dom';
import { fetchAppealDetails } from '../QueueActions';
import { fetchCavcDecisionReasons, fetchInitialDashboardData, fetchCavcSelectionBases } from './cavcDashboardActions';
import LoadingScreen from '../../components/LoadingScreen';
import { LOGO_COLORS } from '../../constants/AppConstants';
import COPY from '../../../COPY';
import StatusMessage from '../../components/StatusMessage';
import TabWindow from '../../components/TabWindow';
import CavcDashboardTab from './CavcDashboardTab';

const CavcDashboard = (props) => {
  const { appealId, appeal, appealDetails, cavcRemands } = props;

  const [loaded, setLoaded] = useState(false);
  const [error, setError] = useState(false);
  const [tabs, setTabs] = useState();

  useEffect(() => {
    // define the promise inside useEffect so that the component doesn't infinitely rerender
    const loadPromise = Promise.all([
      props.fetchAppealDetails(appealId),
      props.fetchCavcDecisionReasons(),
      props.fetchCavcSelectionBases(),
      props.fetchInitialDashboardData(appealId)
    ]);

    loadPromise.
      catch(() => setError(true)).
      finally(() => setLoaded(true));
  }, []);

  useEffect(() => {
    if (loaded && cavcRemands) {
      setTabs(cavcRemands.map((remand) => {
        const label = `CAVC appeal ${remand.cavc_docket_number}`;
        const page = <CavcDashboardTab remand={remand} />;

        return { label, page };
      }));
    }
  }, [loaded]);

  // Redirect to the CaseDetails page if no remand exists for the provided appealId or if a legacy appeal
  if (loaded && !cavcRemands) {
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
          <>
            <h1>CAVC appeals for {appealDetails?.appellantFullName}</h1>

            <TabWindow tabs={tabs} tabPanelTabIndex={-1} alwaysShowTabs />
          </>
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
  cavcRemands: PropTypes.array,
  fetchAppealDetails: PropTypes.func,
  fetchCavcDecisionReasons: PropTypes.func,
  fetchCavcSelectionBases: PropTypes.func,
  fetchInitialDashboardData: PropTypes.func
};

// mappings and connect are boilerplate for connecting to redux and will be added to in the future
// pass state and ownProps into the function when needed to access them as props
const mapStateToProps = (state, ownProps) => {
  return {
    appeal: state.queue.appeals[ownProps.appealId],
    appealDetails: state.queue.appealDetails[ownProps.appealId],
    cavcRemands: state.cavcDashboard.cavc_remands
  };
};

// any actions being used in the component that use/affect the redux store should be mapped here, see
// CaseDetailsLoadingScreen.jsx for example
const mapDispatchToProps = (dispatch) =>
  bindActionCreators({
    fetchAppealDetails,
    fetchCavcDecisionReasons,
    fetchCavcSelectionBases,
    fetchInitialDashboardData
  }, dispatch);

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(CavcDashboard);
