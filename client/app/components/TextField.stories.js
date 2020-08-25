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

const UncontrolledTpl = (args) => <TextField {...args} />;

const ControlledTpl = (args) => {
  // Storybook devs suggest using the useArgs hook for this purpose, but there is currently an issue
  // that impedes usability within the Docs tab:
  // https://github.com/storybookjs/storybook/issues/11657
  //   const [_args, updateArgs] = useArgs();
  //   const handleChange = (value) => updateArgs({ value });
  const [value, setValue] = useState('');
  const handleChange = (val) => setValue(val);

  return <TextField {...args} onChange={handleChange} value={value} />;
};

export const Uncontrolled = UncontrolledTpl.bind({});
Uncontrolled.args = { ...config.args, name: 'uncontrolled' };
Uncontrolled.argTypes = { ...config.argTypes };

export const Controlled = ControlledTpl.bind({});
Controlled.args = { ...config.args, name: 'controlled' };
Controlled.argTypes = { ...config.argTypes };

// export default config;
