import React, { useState } from 'react';
import PropTypes from 'prop-types';
import ApiUtil from '../util/ApiUtil';

import RadioField from '../components/RadioField';
import COPY from '../../COPY';

const radioOptions = [
  { displayText: 'Pexip',
    value: 'pexip' },
  { displayText: 'Webex',
    value: 'webex' }
];

const SelectConferenceTypeRadioField = ({ name, meetingType, organization, user }) => {
  const [value, setValue] = useState(meetingType);

  const modifyConferenceType = (newMeetingType) => {
    const payload = { data: { ...user, attributes: { ...user.attributes, meeting_type: newMeetingType } } };
    console.log(newMeetingType);

    ApiUtil.patch(`/organizations/${organization}/users/${user.id}`, payload).then((response) => {
      console.log(response);
    });

  console.log(newMeetingType);
  };

  return (
    <>
      <RadioField
        label={COPY.USER_MANAGEMENT_SELECT_HEARINGS_CONFERENCE_TYPE}
        name={name}
        options={radioOptions}
        value={value}
        onChange={((newValue) => setValue(newValue) || modifyConferenceType(newValue))}
        vertical
      /></>
  );
};

SelectConferenceTypeRadioField.propTypes = {
  name: PropTypes.number,
  onClick: PropTypes.func,
  meetingType: PropTypes.string,
  organization: PropTypes.string,
  user: PropTypes.shape({
    id: PropTypes.number,
    attributes: PropTypes.object
  })
};

export default SelectConferenceTypeRadioField;
