import React, { useState } from 'react';

import InlineForm from './InlineForm';

import NumberField from './NumberField';
import Button from './Button';

const Template = (args) => {
  const [number, setNumber] = useState(5);

  return <InlineForm {...args}>
    <NumberField
      label="Enter the number of people working today"
      name="employeeCount"
      isInteger
      value={number}
      onChange={setNumber}
    />
    <Button name="Update" />
  </InlineForm>;
};

export const Default = Template.bind({});
