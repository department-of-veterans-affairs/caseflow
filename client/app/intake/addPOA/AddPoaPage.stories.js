import React from 'react';
import { MemoryRouter } from 'react-router';

import { AddPoaPage } from './AddPoaPage';

import ReduxBase from 'app/components/ReduxBase';
import { reducer, generateInitialState } from 'app/intake';
import { PAGE_PATHS } from '../constants';
import faker from 'faker';

// Set up sample data & async fn for performing fuzzy search
// Actual implementation performs fuzzy search via backend ruby gem
const totalRecords = 500;
const data = Array.from({ length: totalRecords }, () => ({
  name: faker.name.findName(),
  participant_id: faker.random.number({
    min: 600000000,
    max: 600000000 + totalRecords,
  }),
  address: {
    addressLine1: faker.address.streetAddress(),
    addressLine2: faker.address.secondaryAddress(),
    city: faker.address.city(),
    state: faker.address.stateAbbr(),
    zip: faker.address.zipCode(),
  },
}));

const performQuery = async (search = '') => {
  const regex = RegExp(search, 'i');

  return data.filter((item) => regex.test(item.name));
};

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

const ReduxDecoratorHLR = (Story) => {
  const hlrState = generateInitialState();

  hlrState.intake.formType = 'higher_level_review';

  return <ReduxBase reducer={reducer} initialState={hlrState} >
    <Story />
  </ReduxBase>;
};

const ReduxDecoratorSC = (Story) => {
  const hlrState = generateInitialState();

  hlrState.intake.formType = 'supplemental_claim';

  return <ReduxBase reducer={reducer} initialState={hlrState} >
    <Story />
  </ReduxBase>;
};

export default {
  title: 'Intake/Add Claimant/AddPoaPage',
  component: AddPoaPage,
  decorators: [ReduxDecorator, RouterDecorator],
  parameters: {},
  args: {
    onAttorneySearch: performQuery
  },
  argTypes: {
    onCancel: { action: 'cancel' },
    onSubmit: { action: 'submit' }
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

export const HigherLevelReviewAddPOA = Template.bind({});
HigherLevelReviewAddPOA.decorators = [ReduxDecoratorHLR, RouterDecorator];
HigherLevelReviewAddPOA.parameters = {
  docs: {
    storyDescription:
      'This is used to add Power of attorneys associated with the higher level review',
  },
};

export const SupplmentalClaimAddPOA = Template.bind({});
SupplmentalClaimAddPOA.decorators = [ReduxDecoratorSC, RouterDecorator];
SupplmentalClaimAddPOA.parameters = {
  docs: {
    storyDescription:
      'This is used to add Power of attorneys associated with the supplemental claim',
  },
};
