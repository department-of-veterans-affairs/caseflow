import React from 'react';
import { CommentIcon } from '../../app/reader/CommentIcon';

export default {
  title: 'Commons/Components/Icons/CommentIcon',
  component: CommentIcon,
  parameters: {
    controls: { expanded: true },
  },
  argTypes: {
    selected: { control: { type: 'boolean' } },
    id: { control: { type: 'range' }, options: [1, 3, 1] },
    size: { control: { type: 'number' } },
    cname: { control: { type: 'text' } }
  },
  args: {
    selected: false,
    id: 1,
    size: 40,
    cname: ''
  }
};

const Template = (args) => <CommentIcon {...args} />;

export const Default = Template.bind({});
