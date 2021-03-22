import React from 'react';
import { useArgs } from '@storybook/client-api';

import NumberField from './NumberField';

/* eslint-disable react/prop-types */
export default {
  title: 'Commons/Components/Form Fields/NumberField',
  component: NumberField,
  parameters: {
    controls: { expanded: true },
  },
  args: {
    label: 'Enter the number of things',
    name: 'things',
    useAriaLabel: true,
    isInteger: true,
  },
  argTypes: { onChange: { action: 'value changed' } }
};

const Template = (args) => {
  // The usage of _args and updateArgs here allows storybook to manage the state
  // eslint-disable-next-line no-unused-vars
  const [_args, updateArgs] = useArgs();

  const handleChange = (value) => {
    // Check or uncheck the box when you click on an option
    updateArgs({ value });
    args.onChange(value);
  };

  return <NumberField {...args} onChange={handleChange} />;
};

export const IntegerOnly = Template.bind({});
export const ReadOnly = Template.bind({});
ReadOnly.args = { readOnly: true };

// This functionality doesn't seem to be used anywhere, or work correctly,
// including here for completeness.
export const DeprecatedAllowDecimal = Template.bind({});
DeprecatedAllowDecimal.args = { isInteger: false };

