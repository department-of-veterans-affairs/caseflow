import React from 'react';

import { CavcReviewExtensionRequestModal } from './CavcReviewExtensionRequestModal';

export default {
  title: 'Queue/Components/CavcReviewExtensionRequestModal',
  component: CavcReviewExtensionRequestModal,
  argTypes: {
    onSubmit: { action: 'submitted' },
    onCancel: { action: 'cancelled' }
  }
};

const Template = (args) => (
  <CavcReviewExtensionRequestModal {...args} />
);

export const Default = Template.bind({});
