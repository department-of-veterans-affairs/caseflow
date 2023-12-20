import React from 'react';
import { sub } from 'date-fns';
import { MemoryRouter } from 'react-router';
import uuid from 'uuid';

import { EditCavcRemandTasksForm } from './editCavcRemandTasksForm';
import {
  sampleTasksForDismissedEvidenceSubmissionDocket,
  sampleTasksForPendingEvidenceSubmissionDocket,
} from 'test/data/queue/cavc/editremandtasks';
import { prepTaskDataForUi, prepOpenTaskDataForUi } from './utils';

const poaType = 'Attorney';

const allDismissedEvidenceSubmissionWindowTasks = sampleTasksForDismissedEvidenceSubmissionDocket();
const filteredDismissedEvidenceSubmissionTasks = prepTaskDataForUi(
  { taskData: allDismissedEvidenceSubmissionWindowTasks, poaType }
);

const allPendingEvidenceSubmissionWindowTasks = sampleTasksForPendingEvidenceSubmissionDocket();
const filteredPendingEvidenceSubmissionTasks = prepTaskDataForUi(
  { taskData: allPendingEvidenceSubmissionWindowTasks, poaType }
);

const activeTasks = prepOpenTaskDataForUi({
  taskData: allPendingEvidenceSubmissionWindowTasks
});

export default {
  title: 'Queue/cavc/editCavcRemandTasks/EditCavcRemandTaksForm',
  component: EditCavcRemandTasksForm,
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
    cancelledTasks: filteredDismissedEvidenceSubmissionTasks,
    activeTasks,
  },
  argTypes: {
    onCancel: { action: 'cancel' },
    onSubmit: { action: 'submit' },
  },
};

const Template = (args) => <EditCavcRemandTasksForm {...args} />;

export const Full = Template.bind({});

Full.parameters = {
  docs: {
    storyDescription:
      'Used by an Intake or Clerk of the Board user to edit a CAVC Remand on an Appeal.',
  },
};

Full.args = {
  activeTasks,
  cancelledTasks: filteredPendingEvidenceSubmissionTasks,
  pendingAppeal: true
};

export const NoActiveTasks = Template.bind({});
NoActiveTasks.args = {
  cancelledTasks: filteredPendingEvidenceSubmissionTasks
};
