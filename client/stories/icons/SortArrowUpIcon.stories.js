import React from 'react';
import { ICON_SIZES, COLORS } from '../../app/constants/AppConstants';
import { SortArrowUpIcon } from '../../app/components/icons/SortArrowUpIcon';

export default {
  title: 'Commons/Components/Icons/SortArrowUpIcon',
  component: SortArrowUpIcon,
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
    color: COLORS.GREY_DARK,
    className: 'cf-sort-arrowup table-icon'
  }
};

const Template = (args) => <SortArrowUpIcon {...args} />;

export const Default = Template.bind({});
