import React from 'react';
import styled from 'styled-components';
import * as Constants from '../../constants';

import RadioField from 'app/components/RadioField';
import TextField from 'app/components/TextField';
import AddressForm from 'app/components/AddressForm';

export const IndividualForm = () => {

  return (
    <>
      <br />
      <TextField
        name="firstName"
        label="First name"
        strongLabel
      />
      <TextField
        name="middleName"
        label="Middle name/initial"
        optional
        strongLabel
      />
      <TextField
        name="lastName"
        label="Last name"
        optional
        strongLabel
      />
      <Suffix>
        <TextField
          name="suffix"
          label="Suffix"
          optional
          strongLabel
        />
      </Suffix>
      <AddressForm />
      <TextField
        name="email"
        label="Claimant email"
        optional
        strongLabel
      />
      <PhoneNumber>
        <TextField
          name="phoneNumber"
          label="Phone number"
          optional
          strongLabel
        />
      </PhoneNumber>
      <RadioField
        options={Constants.BOOLEAN_RADIO_OPTIONS}
        vertical
        label="Do you have a VA Form 21-22 for this claimant?"
        name="vaForm"
        strongLabel
      />
    </>
  );
};

const Suffix = styled.div`
  max-width: 8em;
`;

const PhoneNumber = styled.div`
  width: 240px;
  margin-bottom: 2em;
`;

export default IndividualForm;
