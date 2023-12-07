import React from 'react';
import DocketTimeGoals from './DocketTimeGoals';
import { updatedLevers } from 'test/data/formattedCaseDistributionData';
import { createStore } from 'redux';
import leversReducer from 'app/caseflowDistribution/reducers/Levers/leversReducer';

export default {
  title: 'CaseDistribution/InteractableLevers',
  component: DocketTimeGoals
};

const preloadedState = {
  levers: JSON.parse(JSON.stringify(updatedLevers)),
  initial_levers: JSON.parse(JSON.stringify(updatedLevers))
};

const leverStore = createStore(leversReducer, preloadedState);

const leverDistributionPriorList = [
  'ama_hearings_start_distribution_prior_to_goals',
  'ama_direct_review_start_distribution_prior_to_goals',
  'ama_evidence_submission_start_distribution_prior_to_goals'
];

const leverTimeGoalList = [
  'ama_hearings_docket_time_goals',
  'ama_direct_review_docket_time_goals',
  'ama_evidence_submission_docket_time_goals'
];

const docketLeverLists = {
  leverDistributionPriorList,
  leverTimeGoalList
};
const docketDistributionPriorLevers = [];
const docketTimeGoalLevers = [];

const sectionTitles = [
  'AMA Hearings',
  'AMA Direct Review',
  'AMA Evidence Submission',
];

updatedLevers.forEach((lever) => {
  if (lever.data_type === 'combination' && docketLeverLists.leverDistributionPriorList.includes(lever.item)) {
    docketDistributionPriorLevers.push(lever.item);
  }
  if (lever.data_type === 'number' && docketLeverLists.leverTimeGoalList.includes(lever.item)) {
    docketTimeGoalLevers.push(lever.item);
  }
});

const docketLeversObject = {
  docketDistributionPriorLevers,
  docketTimeGoalLevers,
};

export const docketTimeGoalsAdmin = () => (
  <DocketTimeGoals leverList={docketLeversObject} sectionTitles={sectionTitles} leverStore={leverStore} isAdmin />
);
docketTimeGoalsAdmin.story = {
  name: 'Docket Time Goals for Admin'
};

export const docketTimeGoalsMember = () => (
  <DocketTimeGoals leverList={docketLeversObject} sectionTitles={sectionTitles} leverStore={leverStore} isAdmin={false} />
);
docketTimeGoalsMember.story = {
  name: 'Docket Time Goals for Member'
};
