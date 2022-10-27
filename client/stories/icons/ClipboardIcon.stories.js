import React from 'react';
import { ClipboardIcon } from '../../app/components/icons/ClipboardIcon';
import { ICON_SIZES, COLORS } from '../../app/constants/AppConstants';

export default {
  title: 'Commons/Components/Icons/ClipboardIcon',
  component: ClipboardIcon,
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
    color: COLORS.GREY,
    className: ''
  }
};

const Template = (args) => <ClipboardIcon {...args} />;

export const Default = Template.bind({});
