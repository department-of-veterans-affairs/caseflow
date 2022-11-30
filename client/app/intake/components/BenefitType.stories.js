import React from 'react';

import BenefitType from './BenefitType';

export default {
  title: 'Intake/Review/Benefit Type',
  component: BenefitType,
  decorators: [],
  parameters: {},
  args: {},
  argTypes: {
  },
};

const Template = (args) => (<BenefitType {...args} />);

export const basic = Template.bind({});
