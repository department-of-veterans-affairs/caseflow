import React from 'react';

import { AddClaimantForm } from './AddClaimantForm';

export default {
  title: 'Intake/Add Claimant/AddClaimantForm',
  component: AddClaimantForm,
  decorators: [],
  parameters: {},
  argTypes: {
    onCancel: { action: 'cancel' },
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
