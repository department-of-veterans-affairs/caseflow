import React from 'react';
import { RightTriangle } from '../../app/components/icons/RightTriangle';

export default {
  title: 'Commons/Components/Icons/RightTriangle',
  component: RightTriangle,
  parameters: {
    controls: { expanded: true },
  },
  argTypes: {
    color: { control: { type: 'color' } },
    size: { control: { type: 'number' } },
    cname: { control: { type: 'text' } }
  },
  args: {
    color: '#000000',
    size: 18,
    cname: ''
  }
};

const Template = (args) => <RightTriangle {...args} />;

export const Default = Template.bind({});
