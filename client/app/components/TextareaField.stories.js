import React, { useState } from 'react';

// import { useArgs } from '@storybook/client-api';

import TextareaField from './TextareaField';

export default {
  title: 'Commons/Components/Form Fields/TextareaField',
  component: TextareaField,
  parameters: {
    controls: { expanded: true },
  },

  args: {
    name: 'textArea',
    label: 'Enter some text',
  },
  argTypes: {},
};

const Template = (args) => {
  // See https://github.com/storybookjs/storybook/issues/11657
  //   const [_args, updateArgs] = useArgs();
  //   const handleChange = (value) => updateArgs({ value });
  const [value, setValue] = useState('');
  const handleChange = (val) => setValue(val);

  return <TextareaField {...args} onChange={handleChange} value={value} />;
};

export const Basic = Template.bind({});

export const CharacterLimit = Template.bind({});
CharacterLimit.args = {
  maxlength: 100,
  label: 'Enter your text here (with character limit)'
};
