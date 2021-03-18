import React, { useState } from 'react';

import NumberField from './NumberField';

const Template = () => {
  const [number, setNumber] = useState(5);

  return <NumberField
    label="Enter the number of things"
    name="things"
    isInteger
    value={number}
    onChange={setNumber}
  />;
};

export const Default = Template.bind({});
