import React from 'react';
import { ICON_SIZES, COLORS } from '../../app/constants/AppConstants';
import { ChevronUpIcon } from '../../app/components/icons/ChevronUpIcon';

export default {
  title: 'Commons/Components/Icons/ChevronUpIcon',
  component: ChevronUpIcon,
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

const Template = (args) => <ChevronUpIcon {...args} />;

export const Default = Template.bind({});
