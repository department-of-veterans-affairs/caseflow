import React from 'react';

import MstBadgeComponent from './MstBadge';

export default {
  title: 'Commons/Components/Badges/MST Badge',
  component: MstBadgeComponent,
  parameters: {
    layout: 'centered',
  },
  args: {
    appeal: {
      mst: true,
    }
  }
};

const Template = (args) => <MstBadgeComponent {...args} />;

export const MSTBadge = Template.bind({});
