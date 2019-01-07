import React from 'react';
import ReduxBase from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/ReduxBase';
import NavigationBar from '../components/NavigationBar';
import { BrowserRouter } from 'react-router-dom';
import PageRoute from '../components/PageRoute';
import AppFrame from '../components/AppFrame';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import { LOGO_COLORS } from '../constants/AppConstants';
import Footer from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Footer';

import ReviewPage from './pages/ReviewPage';
import DispositionPage from './pages/DispositionPage';
import { nonCompReducer, mapDataToInitialState } from './reducers';

class NonComp extends React.PureComponent {
  render() {
    const Router = this.props.router || BrowserRouter;
    const initialState = mapDataToInitialState(this.props);
    const appName = 'Lines of Business';

    return <ReduxBase initialState={initialState} reducer={nonCompReducer}>
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
            topMessage={null}
            defaultUrl="/">
            <AppFrame>
              <AppSegment filledBackground>
                <div>
                  <PageRoute
                    exact
                    path="/:businessLineSlug/tasks/:taskId"
                    title="Dispositions | Caseflow"
                    component={DispositionPage} />
                  <PageRoute
                    exact
                    path="/:businessLineSlug"
                    title="Reviews | Caseflow"
                    component={ReviewPage} />
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

export default NonComp;
