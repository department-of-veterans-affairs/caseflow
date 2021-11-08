import React from 'react';
import { Trashcan } from '../../app/components/icons/Trashcan';

export default {
  title: 'Commons/Components/Icons/Trashcan',
  component: Trashcan,
  parameters: {
    controls: { expanded: true },
  },
  argTypes: {
    size: { control: { type: 'number' } },
    color: { control: { type: 'color' } },
    cname: { control: { type: 'text' } }
  },
  args: {
    size: 26,
    color: '',
    cname: ''
  }
};

const Template = (args) => <Trashcan {...args} />;

export const Default = Template.bind({});
