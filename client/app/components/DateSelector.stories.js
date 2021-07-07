import React from 'react';

import { useArgs } from '@storybook/client-api';

import DateSelector from './DateSelector';

export default {
  title: 'Commons/Components/DateSelector',
  component: DateSelector,
  decorators: [],
  args: {
    name: 'datefield',
    label: 'Enter Date',
  },
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

  return <DateSelector {...args} onChange={handleChange} />;
};

export const Default = Template.bind({});

export const ReadOnly = Template.bind({});
ReadOnly.args = {
  value: '2020-01-30',
  readOnly: true,
};

export const ErrorMsg = Template.bind({});
ErrorMsg.args = {
  errorMessage: 'Something is wrong',
};

export const DateErrorMsg = Template.bind({});
DateErrorMsg.args = {
  dateErrorMessage: 'Invalid date',
};

const UncontrolledTemplate = (args) => <DateSelector {...args} />;

export const Uncontrolled = UncontrolledTemplate.bind({});
Uncontrolled.args = {
  name: 'uncontrolled',
  value: undefined
};
