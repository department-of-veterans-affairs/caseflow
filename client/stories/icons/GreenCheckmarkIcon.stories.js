import React from 'react';
import { GreenCheckmarkIcon } from '../../app/components/icons/GreenCheckmarkIcon';

export default {
  title: 'Commons/Components/Icons/GreenCheckmarkIcon',
  component: GreenCheckmarkIcon,
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

const Template = (args) => <GreenCheckmarkIcon {...args} />;

export const Default = Template.bind({});
Default.decorators = [(Story) => <div style={{ padding: '20px', background: '#333' }}><Story /></div>];
