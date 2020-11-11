import React from 'react';

import { EditNODModal } from './EditNODModal';

export default {
  title: 'Queue/EditNODModal',
  component: EditNODModal,
  decorators: [],
  parameters: {
    docs: {
      inlineStories: false,
      iframeHeight: 700,
    },
  },
  args: {},
  argTypes: {
    onCancel: { action: 'cancel' },
    onSubmit: { action: 'submit' },
  },
};

const Template = (args) => (
  <EditNODModal {...args} />
);

export const Basic = Template.bind({});

Basic.parameters = {
  docs: {
    storyDescription:
      'This is used to edit NOD for a review',
  },
};
