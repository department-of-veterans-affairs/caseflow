import React, { useState } from 'react';

// import { useArgs } from '@storybook/client-api';

import Checkbox from './Checkbox';

export default {
  title: 'Commons/Components/Form Fields/Checkbox',
  component: Checkbox,
  parameters: {
    controls: { expanded: true },
  },
  args: {
    name: 'checkbox',
    label: 'Yes, I like checks',
  },
  argTypes: {
    errorMessage: { control: { type: 'text' } },
    onChange: { action: 'onChange' },
  },
};

const UncontrolledTemplate = (args) => <Checkbox {...args} />;

export const Basic = UncontrolledTemplate.bind({});

const ControlledTemplate = (args) => {
  // See https://github.com/storybookjs/storybook/issues/11657
  //   const [_args, updateArgs] = useArgs();
  //   const handleChange = (value) => updateArgs({ value });
  const [value, setValue] = useState('');
  const handleChange = (val) => setValue(val);

  return <Checkbox {...args} onChange={handleChange} value={value} />;
};

export const Controlled = ControlledTemplate.bind({});
Controlled.parameters = {
  docs: {
    description: {
      story:
        'To use as a controlled component, `value` and `onChange` props must be set',
    },
  },
};
