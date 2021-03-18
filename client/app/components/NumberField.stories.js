import React, { useState } from 'react';

import NumberField from './NumberField';

export default {
  title: 'Commons/Components/Form Fields/NumberField',
  component: NumberField,
  parameters: {
    controls: { expanded: true },
  },
  args: {
  },
  argTypes: {
  },
};

const Template = () => {
  const [number, setNumber] = useState(5);
  // Todo, add readonly story
  // Todo, add isInteger: false story

  return <NumberField
    label="Enter the number of things"
    name="things"
    useAriaLabel
    isInteger
    value={number}
    onChange={setNumber}
  />;
};

export const Default = Template.bind({});
