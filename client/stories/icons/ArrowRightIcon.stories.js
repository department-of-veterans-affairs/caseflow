import React from 'react';
import { ICON_SIZES, COLORS } from '../../app/constants/AppConstants';
import { ArrowRightIcon } from '../../app/components/icons/ArrowRightIcon';

export default {
  title: 'Commons/Components/Icons/ArrowRightIcon',
  component: ArrowRightIcon,
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

const Template = (args) => <ArrowRightIcon {...args} />;

export const Default = Template.bind({});
