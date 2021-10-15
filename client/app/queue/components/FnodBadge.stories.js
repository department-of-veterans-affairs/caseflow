import React from 'react';

import FnodBadge from './FnodBadge';

export default {
  title: 'Commons/Components/Badges/FNOD Badge',
  component: FnodBadge,
  parameters: {
    layout: 'centered',
  },
  args: {
    veteranAppellantDeceased: true,
    tooltipText: 'Content displayed in tooltip; can be string or any React element',
    uniqueId: 'abc123'
  }
};

const Template = (args) => <FnodBadge {...args} />;

export const FNODBadge = Template.bind({});

