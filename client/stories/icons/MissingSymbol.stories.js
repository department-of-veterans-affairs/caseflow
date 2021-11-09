import React from 'react';
import { MissingSymbol } from '../../app/components/icons/MissingSymbol';

export default {
  title: 'Commons/Components/Icons/MissingSymbol',
  component: MissingSymbol,
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

const Template = (args) => <MissingSymbol {...args} />;

export const Default = Template.bind({});
