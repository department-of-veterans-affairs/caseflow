import React from 'react';
import { MemoryRouter } from 'react-router';
import LeverButtonsWrapper from './LeverButtonsWrapper';
import { createStore } from 'redux';
import leversReducer from '../reducers/Levers/leversReducer';

import { levers } from 'test/data/adminCaseDistributionLevers';

const preloadedState = {
  levers: JSON.parse(JSON.stringify(levers)),
  initial_levers: JSON.parse(JSON.stringify(levers))
};
const leverStore = createStore(leversReducer, preloadedState);

const RouterDecorator = (Story) => (
  <MemoryRouter initialEntries={['/']}>
    <Story />
  </MemoryRouter>
);

export default {
  title: 'Admin/Caseflow Distribution/Lever Buttons',
  component: LeverButtonsWrapper,
  decorators: [RouterDecorator]
};

export const ButtonWrapper = () => (
  <LeverButtonsWrapper leverStore={leverStore} />
);
