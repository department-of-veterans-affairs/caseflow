import React from 'react';
import { ClockIcon } from '../../app/components/icons/ClockIcon';

export default {
  title: 'Commons/Components/Icons/ClockIcon',
  component: ClockIcon,
  parameters: {
    controls: { expanded: true },
  },
  argTypes: {
    size: { control: { type: 'number' } },
    color: { control: { type: 'color' } },
    cname: { control: { type: 'text' } },
  },
  args: {
    size: 16,
    color: 'currentColor',
    cname: 'svg-inline--fa fa-clock fa-w-16'
  }
};

const Template = (args) => <ClockIcon {...args} />;

export const Default = Template.bind({});
