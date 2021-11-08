import React from 'react';
import { GreenCheckmark } from '../../app/components/icons/GreenCheckmark';

export default {
  title: 'Commons/Components/Icons/GreenCheckmark',
  component: GreenCheckmark,
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
    size: 40,
    strokeColor: '#ffffff',
    color: '#2E8540',
    cname: 'green-checkmark'
  }
};

const Template = (args) => <GreenCheckmark {...args} />;

export const Default = Template.bind({});
Default.decorators = [(Story) => <div style={{ padding: '20px', background: '#333' }}><Story /></div>];
