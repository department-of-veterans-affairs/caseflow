import React from 'react';
import CaseflowDistributionContent from './CaseflowDistributionContent';
import { createStore } from 'redux';
import leversReducer from 'app/admin/reducers/Levers/leversReducer';
import { formatted_history, formatted_levers } from '../../../../../client/test/data/formattedCaseDistributionData';
import { MemoryRouter } from 'react-router';

const preloadedState = {
  levers: JSON.parse(JSON.stringify(formatted_levers)),
  initial_levers: JSON.parse(JSON.stringify(formatted_levers))
};

const leverStore = createStore(leversReducer, preloadedState);
const RouterDecorator = (Story) => (
  <MemoryRouter initialEntries={['/']}>
    <Story />
  </MemoryRouter>
);

const leverList = ['lever_1', 'lever_2', 'lever_3', 'lever_4'];

export default {
  title: 'Admin/CaseDistribution/Caseflow Distribution Content',
  component: CaseflowDistributionContent,
  decorators: [RouterDecorator]
};

export const Primary = () =>
  <CaseflowDistributionContent
    levers = {formatted_levers}
    activeLevers = {[]}
    staticLevers = {leverList}
    saveChanges = {[]}
    formattedHistory={formatted_history}
    leverStore={leverStore}
    isAdmin
  />;

Primary.story = {
  name: 'Case Distribution for Admin'
};

