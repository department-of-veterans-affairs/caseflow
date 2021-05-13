import React from 'react';
import { sub } from 'date-fns';
import { MemoryRouter } from 'react-router';
import uuid from 'uuid';

import { SubstituteAppellantTasksForm } from './SubstituteAppellantTasksForm';
import { sampleEvidenceSubmissionTasks } from 'test/data/queue/substituteAppellant/tasks';
import { prepTaskDataForUi } from 'app/queue/substituteAppellant/tasks/utils';

const allEvidenceSubmissionWindowTasks = sampleEvidenceSubmissionTasks();

const filteredEvidenceSubmissionTasks = prepTaskDataForUi(
  allEvidenceSubmissionWindowTasks
);

export default {
  title: 'Queue/Substitute Appellant/SubstituteAppellantTasksForm',
  component: SubstituteAppellantTasksForm,
  decorators: [
    (Story) => (
      <MemoryRouter>
        <Story />
      </MemoryRouter>
    ),
  ],
  parameters: {},
  args: {
    appealId: uuid.v4(),
    nodDate: sub(new Date(), { days: 30 }),
    dateOfDeath: sub(new Date(), { days: 15 }),
    substitutionDate: sub(new Date(), { days: 10 }),
    tasks: filteredEvidenceSubmissionTasks,
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
    taskIds: [2, 3]
  },
};
