import React from 'react';

import InlineForm from './InlineForm';

import NumberField from './NumberField';
import Button from './Button';

const Template = (args) => (
  <InlineForm {...args}>
    <NumberField
      label="Enter the number of people working today"
      name="employeeCount"
      isInteger
    />
    <Button name="Update" />
  </InlineForm>
);

export const Default = Template.bind({});
