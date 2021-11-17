import React from 'react';
import { GrayDotIcon } from '../../app/components/icons/GrayDotIcon';

export default {
  title: 'Commons/Components/Icons/GrayDotIcon',
  component: GrayDotIcon,
  parameters: {
    controls: { expanded: true },
  },
  argTypes: {
    size: { control: { type: 'number' } },
    color: { control: { type: 'color' } },
    cname: { control: { type: 'text' } },
    strokeColor: { control: { type: 'color' } }
  },
  args: {
    size: 25,
    color: '#D6D7D9',
    cname: 'gray-dot',
    strokeColor: '#ffffff'
  }
};

const Template = (args) => <GrayDotIcon {...args} />;

export const Default = Template.bind({});
Default.decorators = [(Story) => <div style={{ padding: '20px', background: '#333' }}><Story /></div>];
