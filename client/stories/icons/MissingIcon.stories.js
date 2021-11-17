import React from 'react';
import { MissingIcon } from '../../app/components/icons/MissingIcon';

export default {
  title: 'Commons/Components/Icons/MissingIcon',
  component: MissingIcon,
  parameters: {
    controls: { expanded: true },
  },
  argTypes: {
    color: { control: { type: 'color' } },
    size: { control: { type: 'number' } },
    cname: { control: { type: 'text' } }
  },
  args: {
    color: 'red',
    size: '55',
    cname: 'cf-icon-missing'
  }
};

const Template = (args) => <MissingIcon {...args} />;

export const Default = Template.bind({});
