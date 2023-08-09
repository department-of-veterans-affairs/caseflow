import React, { useState } from 'react';
import PropTypes from 'prop-types';
// import ApiUtil from '../util/ApiUtil';

import RadioField from '../components/RadioField';
import COPY from '../../COPY';

const radioOptions = [
  { displayText: 'Pexip',
    value: '1' },
  { displayText: 'Webex',
    value: '2' }
];

const SelectConferenceTypeRadioField = ({ name, onClick }) => {
  const [value, setValue] = useState('1');

  // const modifyConferenceType = (user) => {
  //   const payload = { data: { user } };

  //   console.log('hi');

  //   ApiUtil.patch(`/organizations/${this.props.organization}/users/${user.id}`, payload);
  // };

  return (
    <>
      <RadioField
        label={COPY.USER_MANAGEMENT_SELECT_HEARINGS_CONFERENCE_TYPE}
        name={name}
        options={radioOptions}
        value={value}
        onChange={((newValue) => setValue(newValue) && onClick)}
        vertical
      /></>
  );
};

SelectConferenceTypeRadioField.propTypes = {
  name: PropTypes.string,
  onClick: PropTypes.func
};

export default SelectConferenceTypeRadioField;
