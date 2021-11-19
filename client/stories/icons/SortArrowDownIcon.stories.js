import React from 'react';
import { ICON_SIZES, COLORS } from '../../app/constants/AppConstants';
import { SortArrowDownIcon } from '../../app/components/icons/SortArrowDownIcon';

export default {
  title: 'Commons/Components/Icons/SortArrowDownIcon',
  component: SortArrowDownIcon,
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
    className: 'cf-sort-arrowdown table-icon'
  }
};

const Template = (args) => <SortArrowDownIcon {...args} />;

export const Default = Template.bind({});
