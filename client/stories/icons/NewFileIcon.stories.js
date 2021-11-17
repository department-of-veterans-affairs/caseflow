import React from 'react';
import { NewFileIcon } from '../../app/components/icons/NewFileIcon';

export default {
  title: 'Commons/Components/Icons/NewFileIcon',
  component: NewFileIcon,
  parameters: {
    controls: { expanded: true },
  },
  argTypes: {
    color: { control: { type: 'color' } },
    size: { control: { type: 'number' } },
    className: { control: { type: 'text' } }
  },
  args: {
    size: 11,
    color: '#844E9F',
    className: ''
  }
};

const Template = (args) => <NewFileIcon {...args} />;

export const Default = Template.bind({});
