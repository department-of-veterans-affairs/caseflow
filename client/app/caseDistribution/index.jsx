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
import CaseSearchLink from '../components/CaseSearchLink';
import BannerDisplay from './components/BannerDisplay';
import CaseDistributionApp from './pages/CaseDistributionApp';
import rootReducer from '../caseDistribution/reducers/root';

class CaseDistribution extends React.PureComponent {

  render() {

    const Router = this.props.router || BrowserRouter;
    const appName = 'Case Distribution';

    return (
      <ReduxBase reducer={rootReducer}>
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
                <BannerDisplay />
                <AppSegment filledBackground>
                  <div>
                    <PageRoute
                      exact
                      path={['/acd-controls', '/case-distribution-controls']}
                      title="Case Distribution | Caseflow"
                      component={() => {
                        return (
                          <CaseDistributionApp
                            acdLeversForStore={this.props.acdLeversForStore}
                            acd_history={this.props.acd_history}
                            user_is_an_acd_admin = {this.props.user_is_an_acd_admin}
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

export default CaseDistribution;
