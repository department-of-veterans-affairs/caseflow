import React, { useState } from 'react';

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
    defaultValue: false,
  },
  argTypes: {
    errorMessage: { control: { type: 'text' } },
    onChange: { action: 'onChange' },
  },
};

const UncontrolledTemplate = (args) => <Checkbox {...args} />;

export const Basic = UncontrolledTemplate.bind({});
Basic.args = { name: 'basic' };

export const DefaultValue = UncontrolledTemplate.bind({});
DefaultValue.args = { name: 'defaultValue-demo', defaultValue: true };
/* eslint-disable max-len */
DefaultValue.parameters = {
  docs: {
    description: {
      story:
        'When using as an uncontrolled component, you can set the initial value using the `defaultValue` prop: ```<Checkbox name="starts-true" defaultValue={true} />```',
    },
  },
};
/* eslint-enable max-len */

export const Disabled = UncontrolledTemplate.bind({});
Disabled.args = { name: 'disabled-demo', disabled: true };

export const Controlled = () => {
  const [value, setValue] = useState(false);
  const handleChange = (val) => setValue(val);

  return (
    <Checkbox
      name="controlled"
      label="I'm a controlled component"
      onChange={handleChange}
      value={value}
    />
  );
};
Controlled.parameters = {
  docs: {
    inlineStories: false,
    description: {
      story:
        'To use as a controlled component, `value` and `onChange` props must be set',
    },
  },
};
