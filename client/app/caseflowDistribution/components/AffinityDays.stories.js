import React from 'react';
import AffinityDays from './AffinityDays';
import { levers } from 'test/data/adminCaseDistributionLevers';
import { createStore } from 'redux';
import leversReducer from '../reducers/Levers/leversReducer';

export default {
  title: 'CaseDistribution/InteractableLevers',
  component: AffinityDays
};

const preloadedState = {
  levers: JSON.parse(JSON.stringify(levers)),
  initial_levers: JSON.parse(JSON.stringify(levers))
};

const leverStore = createStore(leversReducer, preloadedState);

const leverList = ['lever_9', 'lever_13'];
const affinityLevers = [];

levers.forEach((lever) => {
  if (lever.data_type === 'radio' && leverList.includes(lever.item)) {
    affinityLevers.push(lever.item);
  }
});

export const affinityDays = () => (
  <AffinityDays leverList={affinityLevers} leverStore={leverStore} />
);
