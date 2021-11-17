import React from 'react';
import { ReaderCommentIcon } from '../../app/components/icons/ReaderCommentIcon';

export default {
  title: 'Commons/Components/Icons/ReaderCommentIcon',
  component: ReaderCommentIcon,
  parameters: {
    controls: { expanded: true },
  },
  argTypes: {
    selected: { control: { type: 'boolean' } },
    id: { control: { type: 'range' }, options: [1, 3, 1] },
    size: { control: { type: 'number' } },
    className: { control: { type: 'text' } }
  },
  args: {
    selected: false,
    id: 1,
    size: 40,
    className: ''
  }
};

const Template = (args) => <ReaderCommentIcon {...args} />;

export const Default = Template.bind({});
