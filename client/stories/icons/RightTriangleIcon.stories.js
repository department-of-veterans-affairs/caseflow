import React from 'react';
import { RightTriangleIcon } from '../../app/components/icons/RightTriangleIcon';
import { ICON_SIZES, COLORS } from '../../app/constants/AppConstants';

export default {
  title: 'Commons/Components/Icons/RightTriangleIcon',
  component: RightTriangleIcon,
  parameters: {
    controls: { expanded: true },
  },
  argTypes: {
    color: { control: { type: 'color' } },
    size: { control: { type: 'number' } },
    className: { control: { type: 'text' } }
  },
  args: {
    color: COLORS.BASE,
    size: ICON_SIZES.SMALL,
    className: ''
  }
};

const Template = (args) => <RightTriangleIcon {...args} />;

export const Default = Template.bind({});
