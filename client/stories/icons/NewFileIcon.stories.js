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
    cname: { control: { type: 'text' } }
  },
  args: {
    size: 11,
    color: '#844E9F',
    cname: ''
  }
};

const Template = (args) => <NewFileIcon {...args} />;

export const Default = Template.bind({});
