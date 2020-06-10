import React from 'react';

import { action } from '@storybook/addon-actions';
import { DecisionHyperlinks } from './DecisionHyperlinks';

export default {
  title: 'Queue/Motions to Vacate/Motions Attorney/DecisionHyperlinks',
  component: DecisionHyperlinks,
  decorators: []
};

export const granted = () => <DecisionHyperlinks onChange={action('change', 'granted')} disposition="granted" />;

granted.story = {
  parameters: {
    docs: {
      storyDescription: 'This is used by attorney to add hyperlinks for decision documents (grant-type disposition)'
    }
  }
};

export const denied = () => <DecisionHyperlinks onChange={action('change', 'denied')} disposition="denied" />;

denied.story = {
  parameters: {
    docs: {
      storyDescription: 'This is used by attorney to add hyperlinks for decision documents (denied disposition)'
    }
  }
};
