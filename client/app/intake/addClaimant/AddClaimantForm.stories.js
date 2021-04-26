import React from 'react';
import faker from 'faker';

import { AddClaimantForm } from './AddClaimantForm';
import { useAddClaimantForm } from './utils';
import { FormProvider } from 'react-hook-form';

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

export const performQuery = async (search = '') => {
  const regex = RegExp(search, 'i');

  return data.filter((item) => regex.test(item.name));
};

// eslint-disable-next-line react/prop-types
const Wrapper = ({ children }) => {
  const methods = useAddClaimantForm();

  return <FormProvider {...methods}>{children}</FormProvider>;
};

export default {
  title: 'Intake/Add Claimant/AddClaimantForm',
  component: AddClaimantForm,
  decorators: [
    (Story) => (
      <Wrapper>
        <Story />
      </Wrapper>
    ),
  ],
  parameters: {},
  args: {
    onAttorneySearch: performQuery,
  },
  argTypes: {
    onBack: { action: 'cancel' },
    onSubmit: { action: 'submit' },
  },
};

const Template = (args) => <AddClaimantForm {...args} />;

export const Basic = Template.bind({});

Basic.parameters = {
  docs: {
    storyDescription:
      'This is used to add claimants not already associated with the appeal',
  },
};
