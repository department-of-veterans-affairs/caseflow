import React from 'react';
import { KeyboardIcon } from '../../app/components/icons/KeyboardIcon';

export default {
  title: 'Commons/Components/Icons/KeyboardIcon',
  component: KeyboardIcon,
  parameters: {
    controls: { expanded: true },
  },
  argTypes: {
    color: { control: { type: 'color' } },
    size: { control: { type: 'number' } },
    className: { control: { type: 'text' } }
  },
  args: {
    color: '#0872B9',
    size: 17,
    className: ''
  }
};

const Template = (args) => <KeyboardIcon {...args} />;

export const Default = Template.bind({});
