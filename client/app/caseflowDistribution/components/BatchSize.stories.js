import React from 'react';
import BatchSize from './BatchSize';
import { levers } from 'test/data/adminCaseDistributionLevers';
import { createStore } from 'redux';
import leversReducer from 'app/caseflowDistribution/reducers/Levers/leversReducer';

export default {
  title: 'Admin/Caseflow Distribution/InteractableLevers',
  component: BatchSize
};

const preloadedState = {
  levers: JSON.parse(JSON.stringify(levers)),
  initial_levers: JSON.parse(JSON.stringify(levers))
};

const leverStore = createStore(leversReducer, preloadedState);

const leverList = ['lever_5', 'lever_6', 'lever_7', 'lever_8'];
const batchSizeLevers = [];

levers.forEach((lever) => {
  if (lever.data_type === 'number' && leverList.includes(lever.item)) {
    batchSizeLevers.push(lever.item);
  }
});

export const batchSize = () => (
  <BatchSize leverList={batchSizeLevers} leverStore={leverStore} />
);
