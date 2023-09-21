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

const SelectConferenceTypeRadioField = ({ name, conferenceProvider, organization, user }) => {
  const [value, setValue] = useState(conferenceProvider);

  const modifyConferenceType = (newConferenceProvider) => {
    const payload = {
      data: { ...user, attributes: { ...user.attributes, conference_provider: newConferenceProvider } }
    };

    ApiUtil.patch(`/organizations/${organization}/users/${user.id}`, payload);
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
  name: PropTypes.string,
  onClick: PropTypes.func,
  conferenceProvider: PropTypes.string,
  organization: PropTypes.string,
  user: PropTypes.shape({
    id: PropTypes.string,
    attributes: PropTypes.object
  })
};

export default SelectConferenceTypeRadioField;
