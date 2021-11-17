import React from 'react';
import { COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';
import { ArrowUpIcon } from '../../app/components/icons/ArrowUpIcon';

export default {
  title: 'Commons/Components/Icons/ArrowUpIcon',
  component: ArrowUpIcon,
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

const Template = (args) => <ArrowUpIcon {...args} />;

export const Default = Template.bind({});
