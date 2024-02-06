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
import leversReducer from './reducers/levers/leversReducer';
import CaseSearchLink from '../components/CaseSearchLink';
import BannerDisplay from './components/BannerDisplay';
import ACD_LEVERS from '../../constants/ACD_LEVERS';
import DISTRIBUTION from '../../constants/DISTRIBUTION';

import CaseDistributionApp from './pages/CaseDistributionApp';
import { createStore } from 'redux';
import rootReducer from '../caseDistribution/reducers/root';

class CaseDistribution extends React.PureComponent {

  render() {
    const preloadedState = {
      levers: JSON.parse(JSON.stringify(this.props.acd_levers)),
      historyList: JSON.parse(JSON.stringify(this.props.acd_history)),
      isUserAcdAdmin: JSON.parse(JSON.stringify(this.props.user_is_an_acd_admin))
    };

    const leverStore = createStore(leversReducer, preloadedState);
    const Router = this.props.router || BrowserRouter;
    const appName = 'Case Distribution';

    const batchLeverList = [
      DISTRIBUTION.alternative_batch_size,
      DISTRIBUTION.batch_size_per_attorney,
      DISTRIBUTION.request_more_cases_minimum
    ];
    let batchSizeLevers = [];
    const affinityLeverList = [
      DISTRIBUTION.ama_hearing_case_affinity_days,
      DISTRIBUTION.ama_hearing_case_aod_affinity_days,
      DISTRIBUTION.cavc_affinity_days,
      DISTRIBUTION.cavc_aod_affinity_days,
      DISTRIBUTION.aoj_affinity_days,
      DISTRIBUTION.aoj_aod_affinity_days,
      DISTRIBUTION.aoj_cavc_affinity_days
    ];
    let affinityLevers = [];
    const docketDistributionPriorLeverList = [
      DISTRIBUTION.ama_hearings_start_distribution_prior_to_goals,
      DISTRIBUTION.ama_direct_review_start_distribution_prior_to_goals,
      DISTRIBUTION.ama_evidence_submission_start_distribution_prior_to_goals,
    ];
    const docketTimeGoalLeverList = [
      DISTRIBUTION.ama_hearings_docket_time_goals,
      DISTRIBUTION.ama_direct_review_docket_time_goals,
      DISTRIBUTION.ama_evidence_submission_docket_time_goals,
    ];

    const docketLeverLists = {
      docketDistributionPriorLeverList,
      docketTimeGoalLeverList
    };
    let docketDistributionPriorLevers = [];
    let docketTimeGoalLevers = [];

    this.props.acd_levers.forEach((lever) => {
      if (lever.data_type === ACD_LEVERS.data_types.number && batchLeverList.includes(lever.item)) {
        batchSizeLevers.push(lever.item);
      }
      if (lever.data_type === ACD_LEVERS.data_types.radio && affinityLeverList.includes(lever.item)) {
        affinityLevers.push(lever.item);
      }
      if (lever.data_type === (ACD_LEVERS.data_types.combination &&
        docketLeverLists.docketDistributionPriorLeverList.includes(lever.item))) {
        docketDistributionPriorLevers.push(lever.item);
      }
      if (lever.data_type === ACD_LEVERS.data_types.number &&
          docketLeverLists.docketTimeGoalLeverList.includes(lever.item)) {
        docketTimeGoalLevers.push(lever.item);
      }

    });

    let docketLeversObject = {
      docketDistributionPriorLevers,
      docketTimeGoalLevers
    };

    batchSizeLevers = batchSizeLevers.sort((batchA, batchB) =>
      batchLeverList.indexOf(batchA) - batchLeverList.indexOf(batchB));
    affinityLevers = affinityLevers.sort((batchA, batchB) =>
      affinityLeverList.indexOf(batchA) - affinityLeverList.indexOf(batchB));
    docketDistributionPriorLevers = docketDistributionPriorLevers.sort((batchA, batchB) =>
      docketDistributionPriorLeverList.indexOf(batchA) - docketDistributionPriorLeverList.indexOf(batchB));
    docketTimeGoalLevers = docketTimeGoalLevers.sort((batchA, batchB) =>
      docketTimeGoalLeverList.indexOf(batchA) - docketTimeGoalLeverList.indexOf(batchB));

    let leversList = {
      affinityLevers,
      batchSizeLevers,
      docketLeversObject,
    };

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
