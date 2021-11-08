import React from 'react';
import { PencilIcon } from '../../app/components/icons/PencilIcon';

export default {
  title: 'Commons/Components/Icons/PencilIcon',
  component: PencilIcon,
  parameters: {
    controls: { expanded: true },
  },
  argTypes: {
    color: { control: { type: 'color' } },
    size: { control: { type: 'number' } },
    cname: { control: { type: 'text' } }
  },
  args: {
    size: 25,
    color: '#0071BC',
    cname: ''
  }
};

const Template = (args) => <PencilIcon {...args} />;

export const Default = Template.bind({});
