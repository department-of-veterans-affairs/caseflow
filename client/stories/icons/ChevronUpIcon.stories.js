import React from 'react';
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
    cname: { control: { type: 'text' } }
  },
  args: {
    color: '#0872B9',
    size: 10,
    cname: 'table-icon'
  }
};

const Template = (args) => <ChevronUpIcon {...args} />;

export const Default = Template.bind({});
