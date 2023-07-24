import React, { useState } from 'react';
import RadioField from '../components/RadioField';

const radioOptions = [
  { displayText: 'Pexip',
    value: '1'},
  { displayText: 'Webex',
    value: '2'}
];

const SelectConferenceTypeRadioField = ({name}) => {
  const [value, setValue] = useState("1")

  return (
    <div >
      <RadioField
        label="Schedule hearings using:"
        name={name}
        options={radioOptions}
        value={value}
        onChange={(newValue) => setValue(newValue)}
        vertical
    /></div>
  );
}

export default SelectConferenceTypeRadioField;
