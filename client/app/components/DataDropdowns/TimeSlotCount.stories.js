import React from 'react';

import { useArgs } from '@storybook/client-api';

import { TimeSlotCount } from './TimeSlotCount';

export default {
  title: 'Commons/Components/Data Dropdowns/Time Slot Count',
  component: TimeSlotCount,
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

  return <TimeSlotCount {...args} onChange={handleChange} />;
};

export const Default = Template.bind({});
Default.args = {
  value: 8,
};
