import React from 'react';
import { sub } from 'date-fns';
import { DocketSwitchReviewConfirm } from './DocketSwitchReviewConfirm';

const tasks = [
  {
    taskId: 1,
    appealId: 1,
    type: 'TaskTypeA',
    label: 'Task Type A',
    instructions: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit',
  },
  {
    taskId: 2,
    appealId: 1,
    type: 'TaskTypeB',
    label: 'Task Type B',
    instructions: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit',
  },
  {
    taskId: 3,
    appealId: 1,
    type: 'TaskTypeC',
    label: 'Task Type C',
    instructions: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit',
  },
];

const issues = [
  {
    id: 1,
    program: 'compensation',
    description: 'PTSD denied',
    decision_date: sub(new Date(), { days: 10 }),
  },
  {
    id: 2,
    program: 'compensation',
    description: 'Left knee denied',
    decision_date: sub(new Date(), { days: 10 }),
  },
  {
    id: 3,
    program: 'compensation',
    description: 'Right knee denied',
    decision_date: sub(new Date(), { days: 10 }),
  },
  {
    id: 4,
    program: 'compensation',
    description: 'Right knee granted at 90%',
    decision_date: sub(new Date(), { days: 10 }),
  },
];

export default {
  title: 'Queue/Docket Switch/DocketSwitchReviewConfirm',
  component: DocketSwitchReviewConfirm,
  decorators: [
    // AppSegment styling relies on being inside a .cf-content-inside element
    (storyFn) => <div className="cf-content-inside">{storyFn()}</div>,
  ],
  parameters: {},
  args: {
    veteranName: 'Jane Doe',
    docketFrom: 'direct_review',
    docketTo: 'hearing',
    originalReceiptDate: sub(new Date(), { days: 30 }),
    docketSwitchReceiptDate: sub(new Date(), { days: 7 }),
    issuesSwitched: issues,
    tasksKept: tasks,
  },
  argTypes: {
    onBack: { action: 'back' },
    onCancel: { action: 'cancel' },
    onSubmit: { action: 'submit' },
  },
};
const Template = (args) => <DocketSwitchReviewConfirm {...args} />;

export const Basic = Template.bind({});
Basic.parameters = {
  docs: {
    storyDescription:
      'Used by attorney in Clerk of the Board office to complete a grant of a docket switch checkout flow ',
  },
};

export const PartialGrant = Template.bind({});
PartialGrant.args = {
  issuesSwitched: issues.slice(0, 2),
  issuesRemaining: issues.slice(2),
};

export const AlternateClaimant = Template.bind({});
AlternateClaimant.args = {
  claimantName: 'John Doe',
};
