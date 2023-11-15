import React from 'react';
import { MemoryRouter } from 'react-router';
import StaticLeversWrapper from './StaticLeversWrapper';
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

const leverList = ['lever_3', 'lever_2', 'lever_7'];

export default {
  title: 'CaseDistribution/Static Levers Wrapper',
  component: StaticLeversWrapper,
  decorators: [RouterDecorator]
};

export const StaticWrapper = () => (
  <table>
    <tbody>
      <tr>
        <StaticLeversWrapper leverList={leverList} leverStore={leverStore} />
      </tr>
    </tbody>
  </table>
);
