import React from 'react';
import { LinkIcon } from '../../app/components/icons/LinkIcon';

export default {
  title: 'Commons/Components/Icons/LinkIcon',
  component: LinkIcon,
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

const Template = (args) => <LinkIcon {...args} />;

export const Default = Template.bind({});
