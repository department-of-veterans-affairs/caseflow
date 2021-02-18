import React from 'react';
import { MemoryRouter } from 'react-router';

import { AddPoaPage } from './AddPoaPage';

import ReduxBase from 'app/components/ReduxBase';
import { reducer, generateInitialState } from 'app/intake';
import { PAGE_PATHS } from '../constants';

const RouterDecorator = (Story) => (
  <MemoryRouter initialEntries={[PAGE_PATHS.ADD_POWER_OF_ATTORNEY]}>
    <Story />
  </MemoryRouter>
);

const ReduxDecorator = (Story) => (
  <ReduxBase reducer={reducer} initialState={generateInitialState()}>
    <Story />
  </ReduxBase>
);

export default {
  title: 'Intake/Add Claimant/AddPoaPage',
  component: AddPoaPage,
  decorators: [ReduxDecorator, RouterDecorator],
  parameters: {},
  argTypes: {
    onCancel: { action: 'cancel' },
    onSubmit: { action: 'submit' },
  },
};

const Template = (args) => <AddPoaPage {...args} />;

export const Basic = Template.bind({});

Basic.parameters = {
  docs: {
    storyDescription:
      'This is used to add Power of attorneys associated with the appeal',
  },
};