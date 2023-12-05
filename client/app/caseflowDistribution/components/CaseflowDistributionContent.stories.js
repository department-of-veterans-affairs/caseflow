import React from 'react';
import CaseflowDistributionContent from './CaseflowDistributionContent';
import { createStore } from 'redux';
import leversReducer from '../reducers/Levers/leversReducer';
import { formattedHistory, formattedLevers } from 'test/data/formattedCaseDistributionData';
import { MemoryRouter } from 'react-router';

const preloadedState = {
  levers: JSON.parse(JSON.stringify(formattedLevers)),
  initial_levers: JSON.parse(JSON.stringify(formattedLevers))
};

const leverStore = createStore(leversReducer, preloadedState);
const RouterDecorator = (Story) => (
  <MemoryRouter initialEntries={['/']}>
    <Story />
  </MemoryRouter>
);

const staticLevers = ['lever_1', 'lever_2', 'lever_3', 'lever_4'];
const batchLeverList = ['lever_5', 'lever_6', 'lever_7'];
const batchSizeLevers = [];

formattedLevers.forEach((lever) => {
  if (lever.data_type === 'number' && batchLeverList.includes(lever.item)) {
    batchSizeLevers.push(lever.item);
  }
});

const affinityLeverList = ['lever_8', 'lever_9', 'lever_10', 'lever_11', 'lever_12', 'lever_13', 'lever_14'];
const affinityLevers = [];

formattedLevers.forEach((lever) => {
  if (lever.data_type === 'radio' && affinityLeverList.includes(lever.item)) {
    affinityLevers.push(lever.item);
  }
});
const docketLeverList = ['lever_15', 'lever_16', 'lever_17'];
const docketLevers = [];

formattedLevers.forEach((lever) => {
  if (lever.data_type === 'combination' && docketLeverList.includes(lever.item)) {
    docketLevers.push(lever.item);
  }
});

export default {
  title: 'CaseDistribution/Caseflow Distribution Content',
  component: CaseflowDistributionContent,
  decorators: [RouterDecorator]
};

let leversList = {
  staticLevers,
  affinityLevers,
  batchSizeLevers,
  docketLevers
};

export const Primary = () =>
  <CaseflowDistributionContent
    levers = {leversList}
    saveChanges = {[]}
    formattedHistory={formattedHistory}
    leverStore={leverStore}
    isAdmin
  />;

Primary.story = {
  name: 'Case Distribution for Admin'
};

export const MemberView = () =>
  <CaseflowDistributionContent
    levers = {leversList}
    saveChanges = {[]}
    formattedHistory={formattedHistory}
    leverStore={leverStore}
    isAdmin={false}
  />;

MemberView.story = {
  name: 'Case Distribution for Member'
};
