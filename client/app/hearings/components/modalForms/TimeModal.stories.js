import React from 'react';
import { TimeModal } from './TimeModal';

export default {
  title: 'Hearings/Components/Modal Forms/TimeModal',
  component: TimeModal,
  parameters: {
    controls: { expanded: true },
    docs: {
      inlineStories: false,
      iframeHeight: 600,
    },
  },
  args: {
    ro: {
      city: 'Los Angeles, CA',
      timezone: 'America/Los_Angeles'
    }
  },
  argTypes: {
    onConfirm: { action: 'confirmed' },
    onCancel: { action: 'cancelled' },
  },
};

const Template = (args) => {
  return (
    <TimeModal {...args} />
  );
};

export const Basic = Template.bind({});

