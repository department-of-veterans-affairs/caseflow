import React from 'react';
import { sub } from 'date-fns';
import { MemoryRouter } from 'react-router';
import uuid from 'uuid';

import { SubstituteAppellantReview } from './SubstituteAppellantReview';

const relationships = [
  { value: 'CLAIMANT_WITH_PVA_AS_VSO',
    fullName: 'Bob Vance',
    relationshipType: 'Spouse',
    displayText: 'Bob Vance, Spouse',
  },
  { value: '"1129318238"',
    fullName: 'Cathy Smith',
    relationshipType: 'Child',
    displayText: 'Cathy Smith, Child',
  },
];

export default {
  title: 'Queue/Substitute Appellant/SubstituteAppellantReview',
  component: SubstituteAppellantReview,
  decorators: [
    (Story) => (
      <MemoryRouter>
        <Story />
      </MemoryRouter>
    ),
  ],
  parameters: {},
  args: {
    existingValues: { substitutionDate: '2021-02-15',
      participantId: 'CLAIMANT_WITH_PVA_AS_VSO',
    },
  },
  argTypes: {
    onBack: { action: 'back' },
    onCancel: { action: 'cancel' },
    onSubmit: { action: 'submit' },
  },
};

const Template = (args) => <SubstituteAppellantReview {...args} />;

export const Basic = Template.bind({});

Basic.parameters = {
  docs: {
    storyDescription:
      'Used by an Intake or Clerk of the Board user to confirm a substitute appellant\'s information for an appeal',
  },
};
