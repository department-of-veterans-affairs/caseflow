import React from 'react';

import { ReturnToLitSupportAlert } from './ReturnToLitSupportAlert';

export default {
  title:
    'Queue/Motions to Vacate/Judge Address Motion to Vacate/ReturnToLitSupportAlert',
  component: ReturnToLitSupportAlert,
  argTypes: { to: { control: { disable: true } } },
};

const Template = (args) => <ReturnToLitSupportAlert {...args} />;

export const Basic = Template.bind({});
Basic.parameters = {
  docs: {
    storyDescription:
      'This provides a link to allow a judge to return a case to lit support if need be',
  },
};
