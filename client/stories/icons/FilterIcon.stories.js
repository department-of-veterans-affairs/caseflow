import React from 'react';
import { FilterOutlineIcon } from '../../app/components/icons/FilterOutlineIcon';

export default {
  title: 'Commons/Components/Icons/FilterOutlineIcon',
  component: FilterOutlineIcon,
  parameters: {
    controls: { expanded: true },
  },
  argTypes: {
    selected: { control: { type: 'boolean' } },
  },
  args: {
    selected: true
  }
};

const Template = (args) => <FilterOutlineIcon {...args} />;

export const Default = Template.bind({});

