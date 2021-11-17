import React from 'react';
import { TrashcanIcon } from '../../app/components/icons/TrashcanIcon';

export default {
  title: 'Commons/Components/Icons/TrashcanIcon',
  component: TrashcanIcon,
  parameters: {
    controls: { expanded: true },
  },
  argTypes: {
    size: { control: { type: 'number' } },
    color: { control: { type: 'color' } },
    className: { control: { type: 'text' } }
  },
  args: {
    size: 26,
    color: '',
    className: ''
  }
};

const Template = (args) => <TrashcanIcon {...args} />;

export const Default = Template.bind({});
