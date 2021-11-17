import React from 'react';
import { ClipboardIcon } from '../../app/components/icons/ClipboardIcon';

export default {
  title: 'Commons/Components/Icons/ClipboardIcon',
  component: ClipboardIcon,
  parameters: {
    controls: { expanded: true },
  },
  argTypes: {
    color: { control: { type: 'color' } },
    size: { control: { type: 'number' } },
    className: { control: { type: 'text' } }
  },
  args: {
    size: 16,
    color: '#5B616B',
    className: ''
  }
};

const Template = (args) => <ClipboardIcon {...args} />;

export const Default = Template.bind({});
