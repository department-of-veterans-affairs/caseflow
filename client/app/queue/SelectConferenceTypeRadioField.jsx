import React, { useState } from 'react';
import { css } from 'glamor';

import RadioField from '../components/RadioField';
import COPY from '../../COPY';

const radioOptions = [
  { displayText: 'Pexip',
    value: '1'},
  { displayText: 'Webex',
    value: '2'}
];

const SelectConferenceTypeRadioField = ({name}) => {
  const [value, setValue] = useState("1")

  return (
    <div>
      <RadioField
        label={COPY.USER_MANAGEMENT_SELECT_HEARINGS_CONFERENCE_TYPE}
        name={name}
        options={radioOptions}
        value={value}
        onChange={(newValue) => setValue(newValue)}
        vertical
    /></div>
  );
}

export default SelectConferenceTypeRadioField;
