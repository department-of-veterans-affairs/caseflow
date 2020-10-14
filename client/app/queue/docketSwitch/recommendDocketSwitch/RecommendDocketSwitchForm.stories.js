import React from 'react';

import { RecommendDocketSwitchForm } from './RecommendDocketSwitchForm';

const judgeOptions = [
  { value: 1, label: 'Judge 1' },
  { value: 2, label: 'Judge 2' },
];

export default {
  title: 'Queue/Docket Change/RecommendDocketSwitchForm',
  component: RecommendDocketSwitchForm,
  decorators: [],
  parameters: {},
  args: {
    claimantName: 'Jane Doe',
    judgeOptions,
  },
  argTypes: {
    onCancel: { action: 'cancel' },
    onSubmit: { action: 'submit' },
  },
};

const Template = (args) => <RecommendDocketSwitchForm {...args} />;

export const Basic = Template.bind({});

Basic.parameters = {
  docs: {
    storyDescription:
      'Used by attorney at Clerk of the Board office to recommend a ruling to VLJ/Clerk',
  },
};
