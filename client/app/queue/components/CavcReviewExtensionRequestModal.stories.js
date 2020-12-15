import React from 'react';

import { CavcReviewExtensionRequestModal } from './CavcReviewExtensionRequestModal';

export default {
  title: 'Queue/Components/CavcReviewExtensionRequestModal',
  component: CavcReviewExtensionRequestModal,
  argTypes: {
    onSubmit: { action: 'onSubmit' },
    onCancel: { action: 'onCancel' }
  },
  parameters: {
    docs: {
      inlineStories: false,
      iframeHeight: 800,
    },
  },
};

const Template = (args) => (
  <CavcReviewExtensionRequestModal {...args} />
);

export const Default = Template.bind({});
