import React from 'react';
import { ICON_SIZES, COLORS } from '../../app/constants/AppConstants';
import { ChevronDownIcon } from '../../app/components/icons/ChevronDownIcon';

export default {
  title: 'Commons/Components/Icons/ChevronDownIcon',
  component: ChevronDownIcon,
  parameters: {
    controls: { expanded: true },
  },
  argTypes: {
    color: { control: { type: 'color' } },
    size: { control: { type: 'number' } },
    className: { control: { type: 'text' } }
  },
  args: {
    size: ICON_SIZES.XSMALL,
    color: COLORS.PRIMARY,
    className: 'table-icon'
  }
};

const Template = (args) => <ChevronDownIcon {...args} />;

export const Default = Template.bind({});
