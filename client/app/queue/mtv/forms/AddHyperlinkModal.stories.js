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
      iframeHeight: 600
    }
  }
};

export const standard = () => (
  <AddHyperlinkModal onCancel={action('cancel', 'standard')} onSubmit={action('submit', 'standard')} />
);

standard.parameters = {
  docs: {
    storyDescription: 'This is used to add hyperlink options within `DecisionHyperlinks` component'
  }
};
