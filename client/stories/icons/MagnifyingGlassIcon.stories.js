import React from 'react';
import { ICON_SIZES, COLORS } from '../../app/constants/AppConstants';
import { MagnifyingGlassIcon } from '../../app/components/icons/MagnifyingGlassIcon';

export default {
  title: 'Commons/Components/Icons/MagnifyingGlassIcon',
  component: MagnifyingGlassIcon,
  parameters: {
    controls: { expanded: true },
  },
  argTypes: {
    color: { control: { type: 'color' } },
    size: { control: { type: 'number' } },
    className: { control: { type: 'text' } }
  },
  args: {
    size: ICON_SIZES.MEDIUM,
    color: COLORS.GREY_MEDIUM,
    className: ''
  }
};

const Template = (args) => <MagnifyingGlassIcon {...args} />;

export const Default = Template.bind({});
