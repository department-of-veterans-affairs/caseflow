import React from 'react';
import { ICON_SIZES, COLORS } from '../../app/constants/AppConstants';
import { LockIcon } from '../../app/components/icons/LockIcon';

export default {
  title: 'Commons/Components/Icons/LockIcon',
  component: LockIcon,
  parameters: {
    controls: { expanded: true },
  },
  argTypes: {
    size: { control: { type: 'number' } },
    color: { control: { type: 'color' } },
    className: { control: { type: 'text' } },
    title: { control: { type: 'text' } }
  },
  args: {
    size: ICON_SIZES.SMALL,
    color: COLORS.GREY_DARK,
    className: 'cf-lock-icon',
    title: 'Lock Icon'
  }
};

const Template = (args) => <LockIcon {...args} />;

export const Default = Template.bind({});
