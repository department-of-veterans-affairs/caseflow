import React from 'react';
import { Route, StaticRouter } from 'react-router';

import { AddClaimantPage } from './AddClaimantPage';

import { PAGE_PATHS } from 'app/intake/constants';
import ReduxBase from 'app/components/ReduxBase';
import { reducer, generateInitialState } from 'app/intake';

const RouterDecorator = (Story) => (
  <StaticRouter location={{ pathname: PAGE_PATHS.ADD_CLAIMANT }}>
    <Route path={PAGE_PATHS.ADD_CLAIMANT}>
      <Story />
    </Route>
  </StaticRouter>
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
  parameters: {},
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
