import React, { useState } from 'react';

// import { useArgs } from '@storybook/client-api';

import RadioField from './RadioField';

export default {
  title: 'Commons/Components/Form Fields/RadioField',
  component: RadioField,
  parameters: {
    controls: { expanded: true },
  },
  args: {
    name: 'radioField',
    label: 'Enter some text',
    options: [
      { displayText: 'Option 1', value: 'option1' },
      { displayText: 'Option 2', value: 'option2' },
      { displayText: 'Option 3', value: 'option3' },
    ],
  },
  argTypes: {
    onChange: { action: 'onChange' },
  },
};

const UncontrolledTemplate = (args) => <RadioField {...args} />;

export const Basic = UncontrolledTemplate.bind({});

const ControlledTemplate = (args) => {
  // See https://github.com/storybookjs/storybook/issues/11657
  //   const [_args, updateArgs] = useArgs();
  //   const handleChange = (value) => updateArgs({ value });
  const [value, setValue] = useState('');
  const handleChange = (val) => setValue(val);

  return <RadioField {...args} onChange={handleChange} value={value} />;
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
