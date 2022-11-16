import React from 'react';
import { MemoryRouter } from 'react-router';
import { PAGE_PATHS } from '../constants';
import ReduxBase from 'app/components/ReduxBase';
import { reducer, generateInitialState } from 'app/intake';

import NonratingRequestIssueModal from './NonratingRequestIssueModal';

const RouterDecorator = (Story) => (
  <MemoryRouter initialEntries={[PAGE_PATHS.ADD_ISSUES]}>
    <Story />
  </MemoryRouter>
);

const ReduxDecorator = (Story) => {
  const state = generateInitialState();

  // Setup initial state Values
  // state.intake.formType = 'appeal';
  // state.appeal.isStarted = 'STARTED';
  // state.appeal.relationships = relationships;

  return <ReduxBase reducer={reducer} initialState={state}>
    <Story />
  </ReduxBase>;
};

const defaultArgs = {
  intakeData: {
    activeNonratingRequestIssues: []
  },
  featureToggles: {}
};

export default {
  title: 'Intake/Review/Non Rating Request Issue Modal',
  component: NonratingRequestIssueModal,
  decorators: [ReduxDecorator, RouterDecorator],
  parameters: {},
  args: defaultArgs,
  argTypes: {
  },
};

const Template = (args) => (<NonratingRequestIssueModal {...args} />);

// Appeal Review
export const basic = Template.bind({});

export const WithSkipButton = Template.bind({});
WithSkipButton.args = { ...defaultArgs, onSkip: () => true }
