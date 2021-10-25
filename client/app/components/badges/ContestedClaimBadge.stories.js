import React from 'react';

import ContestedClaimBadge from './ContestedClaimBadge';

export default {
  title: 'Commons/Components/Badges/CC Badge',
  component: ContestedClaimBadge,
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

const Template = (args) => <ContestedClaimBadge {...args} />;

export const ContestedBadge = Template.bind({});
