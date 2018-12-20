import React from 'react';
import ReduxBase from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/ReduxBase';
import NavigationBar from '../components/NavigationBar';
import { BrowserRouter } from 'react-router-dom';

import AppFrame from '../components/AppFrame';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import { LOGO_COLORS } from '../constants/AppConstants';
import Footer from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Footer';

import NonCompPage from './pages/NonCompPage';
import { nonCompReducer, mapDataToInitialState } from './reducers';

class NonComp extends React.PureComponent {
  render() {
    const Router = this.props.router || BrowserRouter;
    const initialState = mapDataToInitialState(this.props);
    const appName = 'Organization Queue';

    return <ReduxBase initialState={initialState} reducer={nonCompReducer} analyticsMiddlewareArgs={['intakeEdit']}>
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
                  <NonCompPage />
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
