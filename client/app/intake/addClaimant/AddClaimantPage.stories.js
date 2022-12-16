import React from 'react';
import { MemoryRouter } from 'react-router';

import { AddClaimantPage } from './AddClaimantPage';

import ReduxBase from 'app/components/ReduxBase';
import { reducer, generateInitialState } from 'app/intake';
import { PAGE_PATHS } from '../constants';
import { performQuery } from './ClaimantForm.stories';

const RouterDecorator = (Story) => (
  <MemoryRouter initialEntries={[PAGE_PATHS.ADD_CLAIMANT]}>
    <Story />
  </MemoryRouter>
);

const ReduxDecorator = (Story) => (
  <ReduxBase reducer={reducer} initialState={generateInitialState()}>
    <Story />
  </ReduxBase>
);

export default {
  title: 'Intake/Add Claimant/AddClaimantPage',
  component: AddClaimantPage,
  decorators: [ReduxDecorator, RouterDecorator],
  args: {
    onAttorneySearch: performQuery,
  },
  argTypes: {
    onCancel: { action: 'cancel' },
    onSubmit: { action: 'submit' },
  },
};

const Template = (args) => <AddClaimantPage {...args} />;

export const Basic = Template.bind({});

Basic.parameters = {
  docs: {
    storyDescription:
      'This is used to add claimants not already associated with the appeal',
  },
};
