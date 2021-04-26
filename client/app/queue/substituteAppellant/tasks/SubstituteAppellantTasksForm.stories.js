import { sub } from 'date-fns';
import React from 'react';

import { SubstituteAppellantTasksForm } from './SubstituteAppellantTasksForm';

export default {
  title: 'Queue/Substitute Appellant/SubstituteAppellantTasksForm',
  component: SubstituteAppellantTasksForm,
  decorators: [],
  parameters: {},
  args: {
    nodDate: sub(new Date(), { days: 30 }),
    dateOfDeath: sub(new Date(), { days: 15 }),
    substitutionDate: sub(new Date(), { days: 10 }),
  },
  argTypes: {
    onCancel: { action: 'cancel' },
    onSubmit: { action: 'submit' },
  },
};

const Template = (args) => <SubstituteAppellantTasksForm {...args} />;

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
  },
};
