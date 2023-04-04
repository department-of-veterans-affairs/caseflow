import React from 'react';
import { MemoryRouter } from 'react-router';

import { editCavcRemandReview } from './editCavcRemandReview';
import { queueWrapper as Wrapper } from '../../../../test/data/stores/queueStore';
import { sampleTasksForDismissedEvidenceSubmissionDocket } from 'test/data/queue/cavc/editremandtasks';
import { prepTaskDataForUi } from 'app/queue/cavc/editCavcRemandTasks/utils';

const allEvidenceSubmissionWindowTasks = sampleTasksForDismissedEvidenceSubmissionDocket();

const filteredEvidenceSubmissionTasks = prepTaskDataForUi({ taskData:
  allEvidenceSubmissionWindowTasks }
);

export default {
  title: 'Queue/cavc/editCavcRemandReview/Review',
  component: editCavcRemandReview,
  decorators: [
    (Story) => (
      <MemoryRouter>
        <Story />
      </MemoryRouter>
    ),
  ],
  parameters: {},
  args: {
    existingValues: { substitutionDate: '2022-02-15',
      participantId: 'CLAIMANT_WITH_PVA_AS_VSO',
    },
    tasksToCancel: filteredEvidenceSubmissionTasks.slice(0, 3),
    evidenceSubmissionEndDate: new Date('12/12/2022'),
  },
  argTypes: {
    onBack: { action: 'back' },
    onCancel: { action: 'cancel' },
    onSubmit: { action: 'submit' },
  },
};

const storeArgs = {
  substituteAppellant: {
    relationships: [
      { value: 'CLAIMANT_WITH_PVA_AS_VSO',
        fullName: 'Bob Vance',
        relationshipType: 'Spouse',
        displayText: 'Bob Vance, Spouse',
      },
    ],
  },
};

const Template = (args) => (
  <Wrapper {...storeArgs}>
    <editCavcRemandReview {...args} />
  </Wrapper>
);

export const Basic = Template.bind({});

Basic.parameters = {
  docs: {
    storyDescription:
      'Used by an Intake or Clerk of the Board user to confirm a substitute appellant\'s information for an appeal',
  },
  fullName: 'Cathy Smith',
  relationshipType: 'Child'
};
