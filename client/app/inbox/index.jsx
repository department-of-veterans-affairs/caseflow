/* eslint-disable react/prop-types */

import React from 'react';
import ReduxBase from '../components/ReduxBase';
import NavigationBar from '../components/NavigationBar';
import IntakeLink from '../components/IntakeLink';
import { BrowserRouter } from 'react-router-dom';
import PageRoute from '../components/PageRoute';
import AppFrame from '../components/AppFrame';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import { LOGO_COLORS } from '../constants/AppConstants';
import Footer from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Footer';

import InboxPage from './pages/InboxPage';
import { inboxReducer, mapDataToInitialState } from './reducers';

class Inbox extends React.PureComponent {
  render() {
    const Router = this.props.router || BrowserRouter;
    const initialState = mapDataToInitialState(this.props);
    const appName = 'Inbox';

    return <ReduxBase initialState={initialState} reducer={inboxReducer}>
      <Router {...this.props.routerTestProps}>
        <div>
          <NavigationBar
            appName={appName}
            logoProps={{
              accentColor: LOGO_COLORS.INTAKE.ACCENT,
              overlapColor: LOGO_COLORS.INTAKE.OVERLAP
            }}
            rightNavElement={<IntakeLink />}
            userDisplayName={this.props.userDisplayName}
            dropdownUrls={this.props.dropdownUrls}
            topMessage={null}
            defaultUrl="/">
            <AppFrame>
              <AppSegment filledBackground>
                <div>
                  <PageRoute
                    exact
                    path="/inbox"
                    title="Inbox | Caseflow"
                    component={InboxPage} />
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

export default Inbox;
