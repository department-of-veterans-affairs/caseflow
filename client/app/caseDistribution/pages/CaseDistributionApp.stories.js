import React from 'react';
import CaseDistributionApp from './CaseDistributionApp';
import { createStore, applyMiddleware } from 'redux';
import thunk from 'redux-thunk';
import { Provider } from "react-redux";
import leversReducer from '../reducers/levers/leversReducer';
import { formattedLevers } from 'test/data/formattedCaseDistributionData';
import { MemoryRouter } from 'react-router';
import ACD_LEVERS from '../../../constants/ACD_LEVERS';
import DISTRIBUTION from '../../../constants/DISTRIBUTION';
import rootReducer from '../../caseDistribution/reducers/root';

const getStore = () => createStore(rootReducer, applyMiddleware(thunk));
const store = getStore();

const RouterDecorator = (Story) => (
  <MemoryRouter initialEntries={['/']}>
    <Story />
  </MemoryRouter>
);

export default {
  title: 'CaseDistribution/Caseflow Distribution Content',
  component: CaseDistributionApp,
  decorators: [RouterDecorator]
};

const acdHistory = [];

const preloadedState = {
  levers: JSON.parse(JSON.stringify(formattedLevers)),
  backendLevers: JSON.parse(JSON.stringify(formattedLevers)),
  historyList: JSON.parse(JSON.stringify(acdHistory))
};

const leverStore = createStore(leversReducer, preloadedState);

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

formattedLevers.forEach((lever) => {
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

export const Primary = () =>
  <Provider store={store} >
    <CaseDistributionApp
      acdLeversForStore={formattedLevers}
      acd_levers={leversList}
      acd_history={acdHistory}
      user_is_an_acd_admin
      leverStore={leverStore}
      sectionTitles={sectionTitles}
    />;
  </Provider>;

Primary.story = {
  name: 'Case Distribution for Admin'
};
