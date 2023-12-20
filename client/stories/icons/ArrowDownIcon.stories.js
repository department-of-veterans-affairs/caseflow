import React from 'react';
import { ICON_SIZES, COLORS } from '../../app/constants/AppConstants';
import { ArrowDownIcon } from '../../app/components/icons/ArrowDownIcon';

export default {
  title: 'Commons/Components/Icons/ArrowDownIcon',
  component: ArrowDownIcon,
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

const Template = (args) => <ArrowDownIcon {...args} />;

export const Default = Template.bind({});
