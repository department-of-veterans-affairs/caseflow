import React from 'react';
import { FilterNoOutlineIcon } from '../../app/components/icons/FilterNoOutlineIcon';
import { ICON_SIZES, COLORS } from '../../app/constants/AppConstants';

export default {
  title: 'Commons/Components/Icons/FilterNoOutlineIcon',
  component: FilterNoOutlineIcon,
  parameters: {
    controls: { expanded: true },
  },
  argTypes: {
    size: { control: { type: 'number' } },
    color: { control: { type: 'color' } },
    className: { control: { type: 'text' } },
    title: { control: { type: 'text' } },
    desc: { control: { type: 'text' } }
  },
  args: {
    color: COLORS.WHITE,
    size: ICON_SIZES.SMALL,
    className: 'filter-icon',
    title: 'Filter Icon No Outline'
  }
};

const Template = (args) => <FilterNoOutlineIcon {...args} />;

export const Default = Template.bind({});
Default.decorators = [(Story) => <div style={{ padding: '20px', background: '#333' }}><Story /></div>];

