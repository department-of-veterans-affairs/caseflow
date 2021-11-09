import React from 'react';
import { Keyboard } from '../../app/components/icons/Keyboard';

export default {
  title: 'Commons/Components/Icons/Keyboard',
  component: Keyboard,
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
    size: 17,
    cname: ''
  }
};

const Template = (args) => <Keyboard {...args} />;

export const Default = Template.bind({});
