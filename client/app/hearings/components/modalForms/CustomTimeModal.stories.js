import React from 'react';
import { action } from '@storybook/addon-actions';
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

  args: {
    roTimezone: 'America/Los_Angeles',
  },
  argTypes: {
    closeHandler: { action: 'closed' },
  },
};

const Template = (args) => {
  return (
    <CustomTimeModal {...args} />
  );
};

export const Basic = Template.bind({});

