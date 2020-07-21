import React from 'react';

import { action } from '@storybook/addon-actions';
import { DecisionHyperlinks } from './DecisionHyperlinks';

export default {
  title: 'Queue/Motions to Vacate/Motions Attorney/DecisionHyperlinks',
  component: DecisionHyperlinks,
  argTypes: {
    onChange: { action: 'change' },
    disposition: {
      control: {
        type: 'select',
        options: ['granted', 'partially_granted', 'denied', 'dismissed'],
      },
    }
  },
};

const Template = (args) => <DecisionHyperlinks {...args} />;

export const Granted = Template.bind({});
Granted.args = { disposition: 'granted' };
Granted.parameters = {
  docs: {
    storyDescription:
      'This is used by attorney to add hyperlinks for decision documents (grant-type disposition)',
  },
};

export const Denied = Template.bind({});
Denied.args = { disposition: 'denied' };
Denied.parameters = {
  docs: {
    storyDescription:
      'This is used by attorney to add hyperlinks for decision documents (denied disposition)',
  },
};
