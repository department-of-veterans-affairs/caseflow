import React from 'react';

import IntakeBadgeComponent from './IntakeBadge';

export default {
  title: 'Commons/Components/Badges/Intake Badge',
  component: IntakeBadgeComponent,
  parameters: {
    layout: 'centered',
  },
  args: {
    review: {
      intakeFromVbms: true,
    }
  }
};

const Template = (args) => <IntakeBadgeComponent {...args} />;

export const IntakeBadge = Template.bind({});
