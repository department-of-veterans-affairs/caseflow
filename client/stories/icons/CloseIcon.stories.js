import React from 'react';
import { CloseIcon } from '../../app/components/icons/CloseIcon';
import { ICON_SIZES, COLORS } from '../../app/constants/AppConstants';

export default {
  title: 'Commons/Components/Icons/CloseIcon',
  component: CloseIcon,
  parameters: {
    controls: { expanded: true },
  },
  argTypes: {
    color: { control: { type: 'color' } },
    size: { control: { type: 'number' } },
    className: { control: { type: 'text' } }
  },
  args: {
    size: ICON_SIZES.XLARGE,
    color: COLORS.BASE,
    className: 'cf-icon-close'
  }
};

const Template = (args) => <CloseIcon {...args} />;

export const Default = Template.bind({});
