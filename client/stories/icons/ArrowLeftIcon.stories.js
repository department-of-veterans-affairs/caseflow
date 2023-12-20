import React from 'react';
import { ICON_SIZES, COLORS } from '../../app/constants/AppConstants';
import { ArrowLeftIcon } from '../../app/components/icons/ArrowLeftIcon';

export default {
  title: 'Commons/Components/Icons/ArrowLeftIcon',
  component: ArrowLeftIcon,
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

const Template = (args) => <ArrowLeftIcon {...args} />;

export const Default = Template.bind({});
