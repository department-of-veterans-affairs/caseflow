/* eslint-disable react/prop-types */

import React, { useState, useEffect } from 'react';
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
    const showSuccessBanner = leverStore.getState().showSuccessBanner;
    const Router = this.props.router || BrowserRouter;
    const initialState = leversReducer.initialState;
    const appName = 'Caseflow Distribution';

    const staticLevers = [
      'maximum_direct_review_proportion',
      'minimum_legacy_proportion',
      'nod_adjustment',
      'bust_backlog',
    ];
    const batchLeverList = [
      'alternative_batch_size',
      'batch_size_per_attorney',
      'request_more_cases_minimum'
    ];
    const batchSizeLevers = [];
    const affinityLeverList = [
      'ama_hearing_case_affinity_days',
      'ama_hearing_case_aod_affinity_days',
      'cavc_affinity_days',
      'cavc_aod_affinity_days',
      'aoj_affinity_days',
      'aoj_aod_affinity_days',
      'aoj_cavc_affinity_days'
    ];
    const affinityLevers = [];
    const docketDistributionPriorLeverList = [
      'ama_hearings_start_distribution_prior_to_goals',
      'ama_direct_review_start_distribution_prior_to_goals',
      'ama_evidence_submission_start_distribution_prior_to_goals',
    ];
    const docketTimeGoalLeverList = [
      'ama_hearings_docket_time_goals',
      'ama_direct_review_docket_time_goals',
      'ama_evidence_submission_docket_time_goals',
    ];

    const docketLeverLists = {
      docketDistributionPriorLeverList,
      docketTimeGoalLeverList
    };
    const docketDistributionPriorLevers = [];
    const docketTimeGoalLevers = [];

    this.props.acd_levers.forEach((lever) => {
      if (lever.data_type === 'number' && batchLeverList.includes(lever.item)) {
        batchSizeLevers.push(lever.item);
      }
      if (lever.data_type === 'radio' && affinityLeverList.includes(lever.item)) {
        affinityLevers.push(lever.item);
      }
      if (lever.data_type === 'combination' && docketLeverLists.docketDistributionPriorLeverList.includes(lever.item)) {
        docketDistributionPriorLevers.push(lever.item);
      }
      if (lever.data_type === 'number' && docketLeverLists.docketTimeGoalLeverList.includes(lever.item)) {
        docketTimeGoalLevers.push(lever.item);
      }

    });

    let docketLeversObject = {
      docketDistributionPriorLevers,
      docketTimeGoalLevers
    };

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
                      path={["/acd-controls", "/case-distribution-controls"]}
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
