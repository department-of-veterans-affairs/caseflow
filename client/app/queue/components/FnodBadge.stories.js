import React from 'react';

import FnodBadge from './FnodBadge';

export default {
  title: 'Commons/Components/Badges/FNOD Badge',
  component: FnodBadge,
  parameters: {
    layout: 'centered',
  },
  args: {
    appeal: {
      veteran_appellant_deceased: true,
      date_of_death: '2019-03-17'
    },
  }
};

const Template = (args) => (
  <FnodBadge {...args} />
);

export const FNODBadge = Template.bind({});

