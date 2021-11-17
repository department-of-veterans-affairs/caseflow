import React from 'react';
import { LinkSymbol } from '../../app/components/icons/LinkSymbol';

export default {
  title: 'Commons/Components/Icons/LinkSymbol',
  component: LinkSymbol,
  parameters: {
    controls: { expanded: true },
  },
  argTypes: {
    size: { control: { type: 'number' } },
    leftColor: { control: { type: 'color' } },
    rightColor: { control: { type: 'color' } },
    cname: { control: { type: 'text' } },
  },
  args: {
    size: 9,
    leftColor: '#0F0F10',
    rightColor: '#050606',
    cname: ''
  }
};

const Template = (args) => <LinkSymbol {...args} />;

export const Default = Template.bind({});
