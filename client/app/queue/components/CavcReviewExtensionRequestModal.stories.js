import React from 'react';

import { CavcReviewExtensionRequestModalUnconnected } from './CavcReviewExtensionRequestModal';

export default {
  title: 'Queue/Components/CavcReviewExtensionRequestModal',
  component: CavcReviewExtensionRequestModalUnconnected,
  argTypes: {
    onSubmit: { action: 'onSubmit' },
    onCancel: { action: 'onCancel' },
    errorTitle: { type: 'text' },
    errorDetails: { type: 'text' }
  },
  parameters: {
    docs: {
      inlineStories: false,
      iframeHeight: 800,
    },
  },
};

const Template = ({ errorTitle, errorDetails, ...args }) => {
  const error = errorTitle ? { title: errorTitle, detail: errorDetails } : null;

  return <CavcReviewExtensionRequestModalUnconnected error={error} {...args} />;
};

export const Default = Template.bind({});
