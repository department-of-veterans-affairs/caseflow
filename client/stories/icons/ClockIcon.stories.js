import React from 'react';
import { ClockIcon } from '../../app/components/icons/ClockIcon';
import { ICON_SIZES, COLORS } from '../../app/constants/AppConstants';

export default {
  title: 'Commons/Components/Icons/ClockIcon',
  component: ClockIcon,
  parameters: {
    controls: { expanded: true },
  },
  argTypes: {
    size: { control: { type: 'number' } },
    color: { control: { type: 'color' } },
    className: { control: { type: 'text' } },
  },
  args: {
    size: ICON_SIZES.SMALL,
    color: COLORS.BASE,
    className: 'svg-inline--fa fa-clock fa-w-16'
  }
};

const Template = (args) => <ClockIcon {...args} />;

export const Default = Template.bind({});
