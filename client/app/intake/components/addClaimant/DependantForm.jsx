import React from 'react';
import * as Constants from '../../constants';

import RadioField from 'app/components/RadioField';
import TextField from 'app/components/TextField';
import AddressForm from 'app/components/AddressForm'

export const DependantForm = () => {

  return (
    <form>
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
      <TextField
        name="suffix"
        label="Suffix"
        optional
        strongLabel
      />
      {<AddressForm />}
      <TextField
        name="email"
        label="Claimant email"
        optional
        strongLabel
      />
      <TextField
        name="phone number"
        label="Phone number"
        optional
        strongLabel
      />
      {/* ? Ask sally if this should be a copy var */}
      <RadioField
        options={Constants.BOOLEAN_RADIO_OPTIONS}
        vertical
        label="Do you have a VA Form 21-22 for this claimant?"
        name="21-22-radio"
      />
    </form>
  );
};

export default DependantForm;
