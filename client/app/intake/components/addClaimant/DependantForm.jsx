import React from 'react';
import * as Constants from '../../constants';

import RadioField from 'app/components/RadioField';
import TextField from 'app/components/TextField';

export const DependantForm = () => {

  return (
    <form>
      <br />
      <TextField
        label="First name"
        strongLabel
      />
      <TextField
        label="Middle name/initial"
        optional
        strongLabel
      />
      <TextField
        label="Last name"
        optional
        strongLabel
      />
      <TextField
        label="Suffix"
        optional
        strongLabel
      />
      {/* ADDRESS HERE */}
      <TextField
        label="Claimant email"
        optional
        strongLabel
      />
      <TextField
        label="Phone number"
        optional
        strongLabel
      />
      {/* ? Ask sally if this should be a copy var */}
      <RadioField
        options={Constants.BOOLEAN_RADIO_OPTIONS}
        label="Do you have a VA Form 21-22 for this claimant?"
        name="21-22-radio"
      />
    </form>
  );
};

export default DependantForm;
