import React from 'react';

import { EditNodDateModal } from './EditNodDateModal';

export default {
  title: 'Queue/CaseTimeline/EditNodDateModal',
  component: EditNodDateModal,
  decorators: [],
  parameters: {
    docs: {
      inlineStories: false,
      iframeHeight: 700,
    },
  },
  args: {nodDate: '2020-10-01'},
  argTypes: {
    onCancel: { action: 'cancel' },
    onSubmit: { action: 'submit' },
  },
};

const Template = (args) => (
  <EditNodDateModal {...args} />
);

export const Basic = Template.bind({});

Basic.parameters = {
  docs: {
    storyDescription:
      'This is used to edit the NOD date for an appeal',
  },
};
