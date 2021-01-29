import React from 'react';

import { action } from '@storybook/addon-actions';
import { AddHyperlinkModal } from './AddHyperlinkModal';

export default {
  title: 'Queue/Motions to Vacate/Motions Attorney/AddHyperlinkModal',
  component: AddHyperlinkModal,
  decorators: [],
  parameters: {
    docs: {
      inlineStories: false,
      iframeHeight: 600,
    },
  },
};

const Template = (args) => <AddHyperlinkModal {...args} />;

export const Basic = Template.bind({});
Basic.argTypes = {
  onCancel: { action: 'cancel' },
  onSubmit: { action: 'submit' },
};
Basic.parameters = {
  docs: {
    storyDescription:
      'This is used to add hyperlink options within `DecisionHyperlinks` component',
  },
};
