import React from 'react';

import { DocketSwitchReviewRequestForm } from './DocketSwitchReviewRequestForm';

export default {
  title: 'Queue/Docket Switch/DocketSwitchReviewRequestForm',
  component: DocketSwitchReviewRequestForm,
  decorators: [
    // AppSegment styling relies on being inside a .cf-content-inside element
    (storyFn) => <div className="cf-content-inside">{storyFn()}</div>,
  ],
  parameters: {},
  args: {},
  argTypes: {
    onCancel: { action: 'cancel' },
    onSubmit: { action: 'submit' },
  },
};

const Template = (args) => <DocketSwitchReviewRequestForm {...args} />;

export const Basic = Template.bind({});

Basic.parameters = {
  docs: {
    storyDescription: 'Step 1 in docket switch grant checkout flow',
  },
};
