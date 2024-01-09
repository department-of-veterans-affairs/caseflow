import React from 'react';
import CaseDistributionApp from './CaseDistributionApp';
import { createStore } from 'redux';
import leversReducer from '../reducers/levers/leversReducer';
import { formattedHistory, formattedLevers } from 'test/data/formattedCaseDistributionData';
import { MemoryRouter } from 'react-router';

// const preloadedState = {
//   levers: JSON.parse(JSON.stringify(formattedLevers)),
//   initial_levers: JSON.parse(JSON.stringify(formattedLevers))
// };

// const leverStore = createStore(leversReducer, preloadedState);
const RouterDecorator = (Story) => (
  <MemoryRouter initialEntries={['/']}>
    <Story />
  </MemoryRouter>
);

// const staticLevers = ['lever_1', 'lever_2', 'lever_3', 'lever_4'];
// const batchLeverList = ['lever_5', 'lever_6', 'lever_7'];
// const batchSizeLevers = [];

// formattedLevers.forEach((lever) => {
//   if (lever.data_type === 'number' && batchLeverList.includes(lever.item)) {
//     batchSizeLevers.push(lever.item);
//   }
// });

// const affinityLeverList = ['lever_8', 'lever_9', 'lever_10', 'lever_11', 'lever_12', 'lever_13', 'lever_14'];
// const affinityLevers = [];

// formattedLevers.forEach((lever) => {
//   if (lever.data_type === 'radio' && affinityLeverList.includes(lever.item)) {
//     affinityLevers.push(lever.item);
//   }
// });

// const leverDistributionPriorList = ['lever_18', 'lever_19', 'lever_20'];

// const leverTimeGoalList = ['lever_21', 'lever_22', 'lever_23'];

// const docketLeverLists = {
//   leverDistributionPriorList,
//   leverTimeGoalList
// };
// const docketDistributionPriorLevers = [];
// const docketTimeGoalLevers = [];

// const sectionTitles = [
//   'AMA Hearings',
//   'AMA Direct Review',
//   'AMA Evidence Submission',
// ];

// formattedLevers.forEach((lever) => {
//   if (lever.data_type === 'combination' && docketLeverLists.leverDistributionPriorList.includes(lever.item)) {
//     docketDistributionPriorLevers.push(lever.item);
//   }
//   if (lever.data_type === 'number' && docketLeverLists.leverTimeGoalList.includes(lever.item)) {
//     docketTimeGoalLevers.push(lever.item);
//   }
// });

// const docketLeversObject = {
//   docketDistributionPriorLevers,
//   docketTimeGoalLevers,
// };

// const docketLeverList = ['lever_15', 'lever_16', 'lever_17'];
// const docketLevers = [];

// formattedLevers.forEach((lever) => {
//   if (lever.data_type === 'combination' && docketLeverList.includes(lever.item)) {
//     docketLevers.push(lever.item);
//   }
// });

export default {
  title: 'CaseDistribution/Caseflow Distribution Content',
  component: CaseDistributionApp,
  decorators: [RouterDecorator]
};

// let leversList = {
//   staticLevers,
//   affinityLevers,
//   batchSizeLevers,
//   docketLeversObject
// };

const preloadedState = {
  levers: JSON.parse(JSON.stringify(this.props.acd_levers)),
  backendLevers: JSON.parse(JSON.stringify(this.props.acd_levers)),
  historyList: JSON.parse(JSON.stringify(this.props.acd_history))
};

const leverStore = createStore(leversReducer, preloadedState);
leverStore.;
const acdHistory = []

export const Primary = () =>
  <CaseDistributionApp
    acdLeversForStore={this.props.acdLeversForStore}
    acd_levers={leversList}
    acd_history={acdHistory}
    user_is_an_acd_admin = {true}
    leverStore={leverStore}
    sectionTitles={sectionTitles}
  />;

Primary.story = {
  name: 'Case Distribution for Admin'
};
