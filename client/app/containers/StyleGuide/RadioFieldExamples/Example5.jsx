import React, { useState } from 'react';

// components
import RadioField from '../../../components/RadioField';

const options = [
  { displayText: <span>Yosemite National Park</span>,
    value: '1' },
  { displayText: 'Grand Canyon National Park',
    value: '2',
    help: 'Lorem ipsum dolor sit amet' },
  { displayText: 'Yellowstone National Park and related services',
    value: '3' }
];

const Example5 = () => {
  const [value, setValue] = useState('1');

  const onChange = (val) => setValue(val);

  return (
    <RadioField
      label={<h3 id="vertical-radio">With help text</h3>}
      name="radio_example_5"
      options={options}
      value={value}
      onChange={onChange}
    />
  );
};

export default Example5;
