import React, { useState } from 'react';

// import { useArgs } from '@storybook/client-api';

import TextField from './TextField';

const config = {
  title: 'Commons/Components/Form Fields/TextField',
  component: TextField,
  parameters: {
    controls: { expanded: true },
  },
  args: {
    name: 'textfield',
    label: 'Enter some text',
  },
  argTypes: {
    type: {
      control: {
        type: 'select',
        options: ['text', 'number', 'email', 'url', 'tel', 'date'],
      },
    },
  },
};

const Template = (args) => {
  //   const [_args, updateArgs] = useArgs();
  //   const handleChange = (value) => updateArgs({ value });
  const [value, setValue] = useState('');
  const handleChange = (val) => setValue(val);

  return <TextField {...args} onChange={handleChange} value={value} />;
};

export const Basic = Template.bind({});
Basic.args = { name: 'basic', label: 'Enter some text' };
Basic.argTypes = { ...config.argTypes };

export default config;
