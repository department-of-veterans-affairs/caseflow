import React from 'react';
import faker from 'faker';

import { ClaimantForm } from './ClaimantForm';
import { useClaimantForm } from './utils';
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

const performQuery = async (search = '') => {
  const regex = RegExp(search, 'i');

  return data.filter((item) => regex.test(item.name));
};

// eslint-disable-next-line react/prop-types
const Wrapper = ({ children }) => {
  const methods = useClaimantForm();

  return <FormProvider {...methods}>{children}</FormProvider>;
};

export default {
  title: 'Intake/Add Claimant/ClaimantForm',
  component: ClaimantForm,
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

const Template = (args) => <ClaimantForm {...args} />;

export const AddClaimant = Template.bind({});
AddClaimant.parameters = {
  docs: {
    storyDescription:
      'This is used to add claimants not already associated with the appeal'
  }
};

export const EditClaimant = Template.bind({});
EditClaimant.args = {
  editAppellantHeader: 'Edit Appellant Information',
  editAppellantDescription: 'Make any necessary changes to the information and click "save" to confirm your changes.'
};
EditClaimant.parameters = {
  docs: {
    storyDescription:
      'This is used to edit the unrecognized appellant associated with the appeal'
  }
};

export const HlrScAddClaimant = Template.bind({});
HlrScAddClaimant.args = {
  formType: 'higher_level_review',
};
HlrScAddClaimant.parameters = {
  docs: {
    storyDescription:
      'This is used to add claimants not already associated with a higher level review or supplemental claim'
  }
};
