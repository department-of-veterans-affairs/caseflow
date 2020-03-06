import React from 'react';
import PropTypes from 'prop-types';
import ReduxBase from '../components/ReduxBase';
import NavigationBar from '../components/NavigationBar';
import { BrowserRouter } from 'react-router-dom';
import PageRoute from '../components/PageRoute';
import AppFrame from '../components/AppFrame';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import { LOGO_COLORS } from '../constants/AppConstants';
import Footer from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Footer';

import JobsPage from './pages/JobsPage';
import JobPage from './pages/JobPage';
import { asyncableJobsReducer, mapDataToInitialState } from './reducers';

class AsyncableJobs extends React.PureComponent {
  render() {
    const Router = this.props.router || BrowserRouter;
    const initialState = mapDataToInitialState(this.props);
    const appName = 'Background Jobs';

    return (
      <ReduxBase initialState={initialState} reducer={asyncableJobsReducer}>
        <Router {...this.props.routerTestProps}>
          <div>
            <NavigationBar
              appName={appName}
              logoProps={{
                accentColor: LOGO_COLORS.INTAKE.ACCENT,
                overlapColor: LOGO_COLORS.INTAKE.OVERLAP
              }}
              userDisplayName={this.props.userDisplayName}
              dropdownUrls={this.props.dropdownUrls}
              topMessage={null}
              defaultUrl="/"
            >
              <AppFrame>
                <AppSegment filledBackground>
                  <div>
                    <PageRoute exact path="/jobs" title="Background Jobs | Caseflow" component={JobsPage} />
                    <PageRoute
                      exact
                      path="/asyncable_jobs/:asyncable_job_klass/jobs"
                      title="Background Jobs | Caseflow"
                      component={JobsPage}
                    />
                    <PageRoute
                      exact
                      path="/asyncable_jobs/:asyncable_job_klass/jobs/:id"
                      title="Background Jobs | Caseflow"
                      component={JobPage}
                    />
                  </div>
                </AppSegment>
              </AppFrame>
            </NavigationBar>
            <Footer appName={appName} feedbackUrl={this.props.feedbackUrl} buildDate={this.props.buildDate} />
          </div>
        </Router>
      </ReduxBase>
    );
  }
}

AsyncableJobs.propTypes = {
  router: PropTypes.elementType,
  routerTestProps: PropTypes.object,
  dropdownUrls: PropTypes.array,
  userDisplayName: PropTypes.string,
  feedbackUrl: PropTypes.string,
  buildDate: PropTypes.string
};

export default AsyncableJobs;
