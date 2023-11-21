/* eslint-disable react/prop-types */

import React from 'react';
import ReduxBase from '../components/ReduxBase';
import NavigationBar from '../components/NavigationBar';
import { BrowserRouter } from 'react-router-dom';
import PageRoute from '../components/PageRoute';
import AppFrame from '../components/AppFrame';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import { LOGO_COLORS } from '../constants/AppConstants';
import Footer from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Footer';
import leversReducer from './reducers/Levers/leversReducer';
import CaseSearchLink from '../components/CaseSearchLink';

import CaseflowDistributionApp from './pages/CaseflowDistributionApp';
import { createStore } from 'redux';

class CaseflowDistribution extends React.PureComponent {

  render() {
    const preloadedState = {
      levers: JSON.parse(JSON.stringify(this.props.acd_levers)),
      initial_levers: JSON.parse(JSON.stringify(this.props.acd_levers)),
      formatted_history: JSON.parse(JSON.stringify(this.props.acd_history))
    };

    const leverStore = createStore(leversReducer, preloadedState);
    const Router = this.props.router || BrowserRouter;
    const initialState = leversReducer.initialState;
    const appName = 'Caseflow Distribution';

    console.log('this.props:', this.props);
    const { acd_levers, acd_history } = this.props;

    return (
      <ReduxBase initialState={initialState} reducer={leversReducer}>
        <Router {...this.props.routerTestProps}>
          <div>
            <NavigationBar
              wideApp
              defaultUrl={
                this.props.caseSearchHomePage || this.props.hasCaseDetailsRole ?
                  '/search' :
                  '/queue'
              }
              userDisplayName={this.props.userDisplayName}
              dropdownUrls={this.props.dropdownUrls}
              applicationUrls={this.props.applicationUrls}
              logoProps={{
                overlapColor: LOGO_COLORS.QUEUE.OVERLAP,
                accentColor: LOGO_COLORS.QUEUE.ACCENT,
              }}
              rightNavElement={<CaseSearchLink />}
              appName="Caseflow Admin"
            >
              <AppFrame>
                <AppSegment filledBackground>
                  <div>
                    <PageRoute
                      exact
                      path="/acd-controls"
                      title="CaseflowDistribution | Caseflow"
                      component={() => {
                        return (
                          <CaseflowDistributionApp
                            acd_levers={this.props.acd_levers}
                            acd_history={this.props.acd_history}
                            user_is_an_acd_admin = {this.props.user_is_an_acd_admin}
                            leverStore={leverStore}
                          />
                        );
                      }}
                    />
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
      </ReduxBase>
    );
  }
}

export default CaseflowDistribution;
