import React from 'react';
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
    cname: { control: { type: 'text' } }
  },
  args: {
    color: '#0872B9',
    size: 10,
    cname: 'table-icon'
  }
};

const Template = (args) => <ChevronDownIcon {...args} />;

export const Default = Template.bind({});
