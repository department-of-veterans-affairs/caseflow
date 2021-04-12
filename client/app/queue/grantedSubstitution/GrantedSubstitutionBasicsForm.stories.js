import React from 'react';

import { GrantedSubstitutionBasicsForm } from './GrantedSubstitutionBasicsForm';

const relationships = [
  { value: '123456', displayText: 'John Doe, Spouse' },
  { value: '654321', displayText: 'Jen Doe, Child' },
];

export default {
  title: 'Queue/Granted Substitution/GrantedSubstitutionBasicsForm',
  component: GrantedSubstitutionBasicsForm,
  decorators: [],
  parameters: {},
  args: {
    relationships,
  },
  argTypes: {
    onCancel: { action: 'cancel' },
    onSubmit: { action: 'submit' },
  },
};

const Template = (args) => <GrantedSubstitutionBasicsForm {...args} />;

export const Basic = Template.bind({});

Basic.parameters = {
  docs: {
    storyDescription:
      'Used by an Intake or Clerk of the Board user to grant a substitute appellant for an appeal',
  },
};

export const ExistingValues = Template.bind({});
ExistingValues.args = {
  existingValues: {
    substitutionDate: '2021-02-15',
    participantId: relationships[1].value,
  },
};
