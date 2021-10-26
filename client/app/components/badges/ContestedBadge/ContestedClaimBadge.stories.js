import React from 'react';

import ContestedClaimBadgeComponent from './ContestedClaimBadge';

export default {
  title: 'Commons/Components/Badges/CC Badge',
  component: ContestedClaimBadgeComponent,
  parameters: {
    layout: 'centered',
  },
  args: {
    appeal: {
      contestedClaim: true,
    },
    longTooltip: false
  }
};

const Template = (args) => <ContestedClaimBadgeComponent {...args} />;

export const CCBadge = Template.bind({});
