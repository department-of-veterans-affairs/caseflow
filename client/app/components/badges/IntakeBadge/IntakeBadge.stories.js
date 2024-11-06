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
      intakeFromVbms: false,
    }
  }
};

const Template = (args) => <IntakeBadgeComponent {...args} />;

export const IntakeBadgeCF = Template.bind({});

export const IntakeBadgeVBMS = Template.bind({});
IntakeBadgeVBMS.args = {
  review: {
    intakeFromVbms: true,
  }
};
