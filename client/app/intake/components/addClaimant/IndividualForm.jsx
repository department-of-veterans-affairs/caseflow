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
        name="First name"
        label="First name"
        strongLabel
      />
      <TextField
        name="Middle name/initial"
        label="Middle name/initial"
        optional
        strongLabel
      />
      <TextField
        name="Last name"
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
          name="phone number"
          label="Phone number"
          optional
          strongLabel
        />
      </PhoneNumber>
      <RadioField
        options={Constants.BOOLEAN_RADIO_OPTIONS}
        vertical
        label="Do you have a VA Form 21-22 for this claimant?"
        name="21-22-radio"
        strongLabel
      />
    </>
  );
};

// Styles ----------------------------

const Suffix = styled.div`
  max-width: 8em;
`;

const PhoneNumber = styled.div`
  width: 240px;
  margin-bottom: 2em;
`;

export default IndividualForm;
