import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { Redirect } from 'react-router-dom';
import { fetchAppealDetails } from '../QueueActions';
import {
  fetchCavcDecisionReasons,
  fetchInitialDashboardData,
  resetDashboardData,
  fetchCavcSelectionBases,
  saveDashboardData
} from './cavcDashboardActions';
import LoadingScreen from '../../components/LoadingScreen';
import { LOGO_COLORS } from '../../constants/AppConstants';
import COPY from '../../../COPY';
import StatusMessage from '../../components/StatusMessage';
import TabWindow from '../../components/TabWindow';
import CavcDashboardTab from './CavcDashboardTab';
import { CavcDashboardFooter } from './CavcDashboardFooter';

export const CavcDashboard = (props) => {
  const { appealId, appealDetails, cavcDashboards } = props;

  const [loaded, setLoaded] = useState(false);
  const [error, setError] = useState(false);
  const [tabs, setTabs] = useState();

  useEffect(() => {
    // need to reset data on page load or else returning to the dashboard after saving will always enable save button
    if (props.history.location.state && props.history.location.state.redirectFromButton) {
      props.resetDashboardData();
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
    } else {
      props.history.goBack();
    }
  }, []);

  useEffect(() => {
    if (loaded && cavcDashboards) {
      setTabs(cavcDashboards.map((dashboard) => {
        const label = `CAVC appeal ${dashboard.cavc_docket_number}`;
        const page = <CavcDashboardTab
          dashboardId={dashboard.id}
          userCanEdit={props.userCanEdit}
        />;

        return { label, page };
      }));
    }
  }, [loaded, cavcDashboards]);

  // Redirect to the CaseDetails page if no remand exists for the provided appealId
  if (loaded && !cavcDashboards) {
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
          <div className="cf-cavc-dashboard">
            <h1>CAVC appeals for {appealDetails?.appellantFullName}</h1>

            <TabWindow tabs={tabs}
              tabPanelTabIndex={-1}
              alwaysShowTabs
              mountOnEnter={false}
              unmountOnExit={false}
              tabPanelClassName="cavc-tab-panel" />
            <hr />
            <CavcDashboardFooter {...props} />
          </div>
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
  cavcDashboards: PropTypes.array,
  fetchAppealDetails: PropTypes.func,
  fetchCavcDecisionReasons: PropTypes.func,
  fetchCavcSelectionBases: PropTypes.func,
  fetchInitialDashboardData: PropTypes.func,
  resetDashboardData: PropTypes.func,
  saveDashboardData: PropTypes.func,
  userCanEdit: PropTypes.bool,
  // Router inherited props
  history: PropTypes.object
};

const mapStateToProps = (state, ownProps) => {
  return {
    appealDetails: state.queue.appealDetails[ownProps.appealId],
    cavcDashboards: state.cavcDashboard.cavc_dashboards,
    checkedBoxes: state.cavcDashboard.checked_boxes,
    userCanEdit: state.ui.canEditCavcDashboards,
    initialState: state.cavcDashboard.initial_state
  };
};

const mapDispatchToProps = (dispatch) =>
  bindActionCreators({
    fetchAppealDetails,
    fetchCavcDecisionReasons,
    fetchCavcSelectionBases,
    fetchInitialDashboardData,
    resetDashboardData,
    saveDashboardData
  }, dispatch);

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(CavcDashboard);
