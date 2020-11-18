import React from 'react';

import { EditClaimLabelModal } from './EditClaimLabelModal';

export default {
  title: 'Intake/Edit Issues/EditClaimLabelModal',
  component: EditClaimLabelModal,
  decorators: [],
  parameters: {
    docs: {
      inlineStories: false,
      iframeHeight: 700,
    },
  },
  args: {
    existingEpCode: '040HDENR',
  },
  argTypes: {
    onCancel: { action: 'cancel' },
    onSubmit: { action: 'submit' },
  },
};

const Template = (args) => <EditClaimLabelModal {...args} />;

export const Basic = Template.bind({});

Basic.parameters = {
  docs: {
    storyDescription:
      'This is used to edit claim labels on the Edit Issues page',
  },
};
