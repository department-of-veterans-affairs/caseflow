import React from 'react';
import ReduxBase from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/ReduxBase';
import NavigationBar from '../components/NavigationBar';
import { BrowserRouter } from 'react-router-dom';
import PageRoute from '../components/PageRoute';
import AppFrame from '../components/AppFrame';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import { LOGO_COLORS } from '../constants/AppConstants';
import Footer from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Footer';

import JobsPage from './pages/JobsPage';
import { asyncableJobsReducer, mapDataToInitialState } from './reducers';

class AsyncableJobs extends React.PureComponent {
  render() {
    const Router = this.props.router || BrowserRouter;
    const initialState = mapDataToInitialState(this.props);
    const appName = 'Background Jobs';

    return <ReduxBase initialState={initialState} reducer={asyncableJobsReducer}>
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
            defaultUrl="/">
            <AppFrame>
              <AppSegment filledBackground>
                <div>
                  <PageRoute
                    exact
                    path="/jobs"
                    title="Background Jobs | Caseflow"
                    component={JobsPage} />
                  <PageRoute
                    exact
                    path="/asyncable_jobs/:asyncable_job_klass/jobs"
                    title="Background Jobs | Caseflow"
                    component={JobsPage} />
                </div>
              </AppSegment>
            </AppFrame>
          </NavigationBar>
          <Footer
            appName={appName}
            feedbackUrl={this.props.feedbackUrl}
            buildDate={this.props.buildDate}
          />
        </div>
      </Router>
    </ReduxBase>;
  }
}

export default AsyncableJobs;
