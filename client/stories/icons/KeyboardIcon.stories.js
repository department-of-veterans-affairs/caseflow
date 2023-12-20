import React from 'react';
import { KeyboardIcon } from '../../app/components/icons/KeyboardIcon';
import { ICON_SIZES, COLORS } from '../../app/constants/AppConstants';

export default {
  title: 'Commons/Components/Icons/KeyboardIcon',
  component: KeyboardIcon,
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
    color: COLORS.PRIMARY,
    className: ''
  }
};

const Template = (args) => <KeyboardIcon {...args} />;

export const Default = Template.bind({});
