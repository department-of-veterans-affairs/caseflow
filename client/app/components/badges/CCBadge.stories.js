import React from 'react';

import CCBadge from './CCBadge';

export default {
  title: 'Commons/Components/Badges/CC Badge',
  component: CCBadge,
  parameters: {
    layout: 'centered',
  },
  args: {
    appeal: {
      contested_claim: true,
    },
    longTooltip: false
  }
};

const Template = (args) => <CCBadge {...args} />;

export const ContestedBadge = Template.bind({});
