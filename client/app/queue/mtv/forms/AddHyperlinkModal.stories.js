import React from 'react';

import { action } from '@storybook/addon-actions';
import { AddHyperlinkModal } from './AddHyperlinkModal';

export default {
  title: 'Queue/Motions to Vacate/Motions Attorney/AddHyperlinkModal',
  component: AddHyperlinkModal,
  decorators: []
};

export const standard = () => (
  <AddHyperlinkModal onCancel={action('cancel', 'standard')} onSubmit={action('submit', 'standard')} />
);

standard.story = {
  parameters: {
    docs: {
      storyDescription: 'This is used to add hyperlink options within `DecisionHyperlinks` component'
    }
  }
};
