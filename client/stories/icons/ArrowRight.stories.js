import React from 'react';
import { COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';
import { ArrowRight } from '../../app/components/icons/ArrowRight';

export default {
  title: 'Commons/Components/Icons/ArrowRight',
  component: ArrowRight,
  parameters: {
    controls: { expanded: true },
  },
  argTypes: {
    color: { control: { type: 'color' } },
    size: { control: { type: 'number' } },
    cname: { control: { type: 'text' } }
  },
  args: {
    color: COLORS.GREY_DARK,
    size: 17,
    cname: ''
  }
};

const Template = (args) => <ArrowRight {...args} />;

export const Default = Template.bind({});
