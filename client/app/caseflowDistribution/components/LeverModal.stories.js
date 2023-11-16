import React from 'react';
import { MemoryRouter } from 'react-router';
import LeverButtonsWrapper from './LeverButtonsWrapper';
import { createStore } from 'redux';
import leversReducer from '../reducers/Levers/leversReducer';
import { formattedLevers, updatedLevers } from 'test/data/formattedCaseDistributionData';

const preloadedState = {
  levers: JSON.parse(JSON.stringify(updatedLevers)),
  initial_levers: JSON.parse(JSON.stringify(formattedLevers))
};
const leverStore = createStore(leversReducer, preloadedState);

const RouterDecorator = (Story) => (
  <MemoryRouter initialEntries={['/']}>
    <Story />
  </MemoryRouter>
);

export default {
  title: 'CaseDistribution/Lever Modal',
  component: LeverButtonsWrapper,
  decorators: [RouterDecorator]
};

export const ButtonWrapper = () => (
  <LeverButtonsWrapper leverStore={leverStore}/>
);
