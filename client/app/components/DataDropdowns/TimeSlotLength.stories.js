import React from 'react';

import { useArgs } from '@storybook/client-api';

import { TimeSlotLength } from './TimeSlotLength';

export default {
  title: 'Commons/Components/Data Dropdowns/Time Slot Length',
  component: TimeSlotLength,
  decorators: [],
  argTypes: {
    onChange: { action: 'onChange' },
  },
};

const Template = (args) => {
  const [storyArgs, updateStoryArgs] = useArgs();
  const handleChange = (value) => {
    args.onChange(value);
    updateStoryArgs({ ...storyArgs, value });
  };

  return <TimeSlotLength {...args} onChange={handleChange} />;
};

export const Default = Template.bind({});
Default.args = {
  value: 60,
};
