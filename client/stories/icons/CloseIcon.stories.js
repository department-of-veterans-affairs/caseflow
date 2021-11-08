import React from 'react';
import { CloseIcon } from '../../app/components/icons/CloseIcon';

export default {
  title: 'Commons/Components/Icons/CloseIcon',
  component: CloseIcon,
  parameters: {
    controls: { expanded: true },
  },
  argTypes: {
    color: { control: { type: 'color' } },
    size: { control: { type: 'number' } },
    cname: { control: { type: 'text' } }
  },
  args: {
    color: '',
    size: '55',
    cname: ''
  }
};

const Template = (args) => <CloseIcon {...args} />;

export const Default = Template.bind({});
