import React from 'react';
import { RightTriangleIcon } from '../../app/components/icons/RightTriangleIcon';

export default {
  title: 'Commons/Components/Icons/RightTriangleIcon',
  component: RightTriangleIcon,
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

const Template = (args) => <RightTriangleIcon {...args} />;

export const Default = Template.bind({});
