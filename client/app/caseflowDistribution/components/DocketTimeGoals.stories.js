import React from 'react';
import DocketTimeGoals from './DocketTimeGoals';
import { levers } from 'test/data/adminCaseDistributionLevers';
import { createStore } from 'redux';
import leversReducer from 'app/caseflowDistribution/reducers/Levers/leversReducer';

export default {
  title: 'Admin/Caseflow Distribution/InteractableLevers',
  component: DocketTimeGoals
};

const preloadedState = {
  levers: JSON.parse(JSON.stringify(levers)),
  initial_levers: JSON.parse(JSON.stringify(levers))
};

const leverStore = createStore(leversReducer, preloadedState);

const leverList = ['lever_10', 'lever_11', 'lever_12'];
const docketLevers = [];

levers.forEach((lever) => {
  if (lever.data_type === 'combination' && leverList.includes(lever.item)) {
    docketLevers.push(lever.item);
  }
});

export const docketTimeGoals = () => (
  <DocketTimeGoals leverList={docketLevers} leverStore={leverStore} />
);
