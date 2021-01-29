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

const UncontrolledTemplate = (args) => <TextareaField {...args} />;

export const Basic = UncontrolledTemplate.bind({});

const ControlledTemplate = (args) => {
  // See https://github.com/storybookjs/storybook/issues/11657
  //   const [_args, updateArgs] = useArgs();
  //   const handleChange = (value) => updateArgs({ value });
  const [value, setValue] = useState('');
  const handleChange = (val) => setValue(val);

  return <TextareaField {...args} onChange={handleChange} value={value} />;
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

export const CharacterLimit = ControlledTemplate.bind({});

/* eslint-disable max-len */
const charLimitDescription = [
  'Character limits alert users of the maximum possible text input and is used to limit the amount of information a user can provide.',
  'This friction helps ensure the user is providing the appropriate information for the text input.',
  'As the user types inside the text area, the character number decreases while showing the number of characters remaining.',
  'When there are 0 characters remaining, the text box does not allow for more characters to be inserted.',
  'This is enabled by setting the `maxlength` prop.',
].join(' ');
/* eslint-enable max-len */

CharacterLimit.parameters = {
  docs: { description: { story: charLimitDescription } },
};
CharacterLimit.args = {
  maxlength: 100,
  label: 'Enter your text here (with character limit)',
};
