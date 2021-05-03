import React from 'react';
import { CustomTimeModal } from './CustomTimeModal';

export default {
  title: 'Hearings/Components/Modal Forms/CustomTimeModal',
  component: CustomTimeModal,
  parameters: {
    controls: { expanded: true },
    docs: {
      inlineStories: false,
      iframeHeight: 600,
    },
  },
  argTypes: {
    onConfirm: { action: 'confirmed' },
    onCancel: { action: 'cancelled' },
  },
};

const Template = (args) => {
  return (
    <CustomTimeModal {...args} />
  );
};

export const Basic = Template.bind({});

