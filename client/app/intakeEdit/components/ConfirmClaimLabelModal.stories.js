import React from 'react';

import { ConfirmClaimLabelModal } from './ConfirmClaimLabelModal';

export default {
  title: 'Intake/Edit Issues/ConfirmClaimLabelModal',
  component: ConfirmClaimLabelModal,
  decorators: [],
  parameters: {
    docs: {
      inlineStories: false,
      iframeHeight: 700,
    },
  },
  args: {
    previousEpCode: '030HLRR',
    newEpCode: '030HLRNR',
  },
  argTypes: {
    onCancel: { action: 'cancel' },
    onSubmit: { action: 'submit' },
  },
};

const Template = (args) => <ConfirmClaimLabelModal {...args} />;

export const Basic = Template.bind({});

Basic.parameters = {
  docs: {
    storyDescription:
      'This is a confirmation modal the user sees after selecting a new claim label for an end product.',
  },
};
