import React from 'react';
import { CancelIcon } from '../../app/components/icons/CancelIcon';

export default {
  title: 'Commons/Components/Icons/CancelIcon',
  component: CancelIcon,
  parameters: {
    controls: { expanded: true },
  },
  argTypes: {
    size: { control: { type: 'number' } },
    color: { control: { type: 'color' } },
    className: { control: { type: 'text' } },
    bgColor: { control: { type: 'color' } }
  },
  args: {
    size: 40,
    color: '#E31C3D',
    className: '',
    bgColor: '#ffffff'
  }
};

const Template = (args) => <CancelIcon {...args} />;

export const Default = Template.bind({});
Default.decorators = [(Story) => <div style={{ padding: '20px', background: '#333' }}><Story /></div>];
