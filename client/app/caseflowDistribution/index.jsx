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
import BannerDisplay from './components/BannerDisplay';
import ACD_LEVERS from '../../constants/ACD_LEVERS';
import DISTRIBUTION from '../../constants/DISTRIBUTION';

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

    const staticLevers = [
      DISTRIBUTION.maximum_direct_review_proportion,
      DISTRIBUTION.minimum_legacy_proportion,
      DISTRIBUTION.nod_adjustment,
      DISTRIBUTION.bust_backlog,
    ];
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
      if (lever.data_type === ACD_LEVERS.number && batchLeverList.includes(lever.item)) {
        batchSizeLevers.push(lever.item);
      }
      if (lever.data_type === ACD_LEVERS.radio && affinityLeverList.includes(lever.item)) {
        affinityLevers.push(lever.item);
      }
      if (lever.data_type === (ACD_LEVERS.combination &&
        docketLeverLists.docketDistributionPriorLeverList.includes(lever.item))) {
        docketDistributionPriorLevers.push(lever.item);
      }
      if (lever.data_type === ACD_LEVERS.number && docketLeverLists.docketTimeGoalLeverList.includes(lever.item)) {
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
      staticLevers,
      affinityLevers,
      batchSizeLevers,
      docketLeversObject,
    };

    const sectionTitles = [
      'AMA Hearings',
      'AMA Direct Review',
      'AMA Evidence Submission',
    ];

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
                <BannerDisplay leverStore={leverStore} />
                <AppSegment filledBackground>
                  <div>
                    <PageRoute
                      exact
                      path={['/acd-controls', '/case-distribution-controls']}
                      title="CaseflowDistribution | Caseflow"
                      component={() => {
                        return (
                          <CaseflowDistributionApp
                            acd_levers={leversList}
                            acd_history={this.props.acd_history}
                            user_is_an_acd_admin = {this.props.user_is_an_acd_admin}
                            leverStore={leverStore}
                            sectionTitles={sectionTitles}
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
