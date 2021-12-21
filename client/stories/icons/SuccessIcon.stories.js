import React from 'react';
import { SuccessIcon } from '../../app/components/icons/SuccessIcon';

export default {
  title: 'Commons/Components/Icons/SuccessIcon',
  component: SuccessIcon,
  parameters: {
    controls: { expanded: true },
  },
  argTypes: {
    color: { control: { type: 'color' } },
    size: { control: { type: 'number' } },
    className: { control: { type: 'text' } }
  },
  args: {
    color: '',
    size: 55,
    className: 'cf-icon-found'
  }
};

const Template = (args) => <SuccessIcon {...args} />;

export const Default = Template.bind({});
