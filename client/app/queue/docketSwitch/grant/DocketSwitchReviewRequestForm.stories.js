import React from 'react';

import { DocketSwitchReviewRequestForm } from './DocketSwitchReviewRequestForm';

const issues = [
  { id: 1, program: 'compensation', description: 'PTSD denied' },
  { id: 2, program: 'compensation', description: 'Left  knee denied' },
];

export default {
  title: 'Queue/Docket Switch/DocketSwitchReviewRequestForm',
  component: DocketSwitchReviewRequestForm,
  decorators: [
    // AppSegment styling relies on being inside a .cf-content-inside element
    (storyFn) => <div className="cf-content-inside">{storyFn()}</div>,
  ],
  parameters: {},
  args: {
    appellantName: 'Jane Doe',
    docketFrom: 'direct_review',
    issues,
  },
  argTypes: {
    onCancel: { action: 'cancel' },
    onSubmit: { action: 'submit' },
  },
};

const Template = (args) => <DocketSwitchReviewRequestForm {...args} />;

export const Basic = Template.bind({});

Basic.parameters = {
  docs: {
    storyDescription:
      'Used by attorney in Clerk of the Board office to complete a grant of a docket switch checkout flow ',
  },
};
