import React from 'react';

import PactBadgeComponent from './PactBadge';

export default {
  title: 'Commons/Components/Badges/PACT Badge',
  component: PactBadgeComponent,
  parameters: {
    layout: 'centered',
  },
  args: {
    appeal: {
      pact: true,
    }
  }
};

const Template = (args) => <PactBadgeComponent {...args} />;

export const PactBadge = Template.bind({});
