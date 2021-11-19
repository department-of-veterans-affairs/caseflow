import React from 'react';
import { MissingIcon } from '../../app/components/icons/MissingIcon';
import { ICON_SIZES, COLORS } from '../../app/constants/AppConstants';

export default {
  title: 'Commons/Components/Icons/MissingIcon',
  component: MissingIcon,
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
    color: COLORS.RED,
    className: 'cf-icon-missing'
  }
};

const Template = (args) => <MissingIcon {...args} />;

export const Default = Template.bind({});
