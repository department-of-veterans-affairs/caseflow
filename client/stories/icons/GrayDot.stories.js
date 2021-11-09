import React from 'react';
import { GrayDot } from '../../app/components/icons/GrayDot';

export default {
  title: 'Commons/Components/Icons/GrayDot',
  component: GrayDot,
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

const Template = (args) => <GrayDot {...args} />;

export const Default = Template.bind({});
Default.decorators = [(Story) => <div style={{ padding: '20px', background: '#333' }}><Story /></div>];
