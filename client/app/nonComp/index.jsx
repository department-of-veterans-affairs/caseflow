import React from 'react';
import PropTypes from 'prop-types';
import ReduxBase from '../components/ReduxBase';
import NavigationBar from '../components/NavigationBar';
import { BrowserRouter } from 'react-router-dom';
import PageRoute from '../components/PageRoute';
import AppFrame from '../components/AppFrame';
import { LOGO_COLORS } from '../constants/AppConstants';
import Footer from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Footer';
import { FlashAlerts } from './components/Alerts';
import ReviewPage from './pages/ReviewPage';
import TaskPage from './pages/TaskPage';
import ReportPage from './pages/ReportPage';
import SavedSearches from './pages/SavedSearches';
import ClaimHistoryPage from './pages/ClaimHistoryPage';
import CombinedNonCompReducer, { mapDataToInitialState } from './reducers';

class NonComp extends React.PureComponent {
  render() {
    const Router = this.props.router || BrowserRouter;
    const initialState = mapDataToInitialState(this.props);
    const appName = this.props.serverNonComp.businessLine;

    return (
      <ReduxBase initialState={initialState} reducer={CombinedNonCompReducer}>
        <Router basename="/decision_reviews" {...this.props.routerTestProps}>
          <div>
            <NavigationBar
              appName={appName}
              logoProps={{
                accentColor: LOGO_COLORS.INTAKE.ACCENT,
                overlapColor: LOGO_COLORS.INTAKE.OVERLAP
              }}
              userDisplayName={this.props.userDisplayName}
              dropdownUrls={this.props.dropdownUrls}
              applicationUrls={this.props.applicationUrls}
              topMessage={null}
              defaultUrl={`/${this.props.serverNonComp.businessLineUrl}`}
            >
              <AppFrame>
                {this.props.flash && <FlashAlerts flash={this.props.flash} />}
                <PageRoute
                  exact
                  path="/:businessLineSlug/tasks/:taskId/history"
                  title={`${appName} Individual Claim History | Caseflow`}
                  component={ClaimHistoryPage}
                />
                <PageRoute
                  exact
                  path="/:businessLineSlug/tasks/:taskId"
                  title={`${appName} Dispositions | Caseflow`}
                  component={TaskPage}
                />
                <PageRoute
                  exact
                  path="/:businessLineSlug/report"
                  title={`${appName} Generate Task Report | Caseflow`}
                  component={ReportPage}
                />
                <PageRoute
                  exact
                  path="/:businessLineSlug/report/searches"
                  title={`${appName} Saved Searches | Caseflow`}
                  component={SavedSearches}
                />
                <PageRoute
                  exact
                  path="/:businessLineSlug"
                  title={`${appName} Reviews | Caseflow`}
                  component={ReviewPage}
                />
              </AppFrame>
            </NavigationBar>
            <Footer appName={appName} feedbackUrl={this.props.feedbackUrl} buildDate={this.props.buildDate} />
          </div>
        </Router>
      </ReduxBase>
    );
  }
}

NonComp.propTypes = {
  router: PropTypes.elementType,
  routerTestProps: PropTypes.object,
  userDisplayName: PropTypes.string,
  dropdownUrls: PropTypes.array,
  applicationUrls: PropTypes.array,
  feedbackUrl: PropTypes.string,
  buildDate: PropTypes.string,
  flash: PropTypes.array,
  serverNonComp: PropTypes.object.isRequired
};

export default NonComp;
