import React from 'react';
import { COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';
import { ArrowUp } from '../../app/components/icons/ArrowUp';

export default {
  title: 'Commons/Components/Icons/ArrowUp',
  component: ArrowUp,
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

const Template = (args) => <ArrowUp {...args} />;

export const Default = Template.bind({});
