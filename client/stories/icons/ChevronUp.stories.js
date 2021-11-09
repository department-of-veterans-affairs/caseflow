import React from 'react';
import { ChevronUp } from '../../app/components/icons/ChevronUp';

export default {
  title: 'Commons/Components/Icons/ChevronUp',
  component: ChevronUp,
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

const Template = (args) => <ChevronUp {...args} />;

export const Default = Template.bind({});
