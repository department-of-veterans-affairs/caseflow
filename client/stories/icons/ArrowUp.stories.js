import React from 'react';
import { ICON_SIZES, COLORS } from '../../app/constants/AppConstants';
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
    className: { control: { type: 'text' } }
  },
  args: {
    size: ICON_SIZES.SMALL,
    color: COLORS.GREY_DARK,
    className: ''
  }
};

const Template = (args) => <ArrowUpIcon {...args} />;

export const Default = Template.bind({});
