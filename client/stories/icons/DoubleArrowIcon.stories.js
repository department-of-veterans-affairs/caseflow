import React from 'react';
import { ICON_SIZES, COLORS } from '../../app/constants/AppConstants';
import { DoubleArrowIcon } from '../../app/components/icons/DoubleArrowIcon';

export default {
  title: 'Commons/Components/Icons/DoubleArrowIcon',
  component: DoubleArrowIcon,
  parameters: {
    controls: { expanded: true },
  },
  argTypes: {
    topColor: { control: { type: 'color' } },
    bottomColor: { control: { type: 'color' } },
    size: { control: { type: 'number' } },
    className: { control: { type: 'text' } }
  },
  args: {
    topColor: COLORS.GREY_DARK,
    bottomColor: COLORS.GREY_DARK,
    size: ICON_SIZES.SMALL,
    className: 'table-icon'
  }
};

const Template = (args) => <DoubleArrowIcon {...args} />;

export const Default = Template.bind({});
