import React from 'react';
import { ChevronDown } from '../../app/components/icons/ChevronDown';

export default {
  title: 'Commons/Components/Icons/ChevronDown',
  component: ChevronDown,
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

const Template = (args) => <ChevronDown {...args} />;

export const Default = Template.bind({});
