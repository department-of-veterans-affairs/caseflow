import React from 'react';
import * as Constants from '../../constants';

import { useFormContext } from 'react-hook-form';

import AddressForm from 'app/components/AddressForm'
import RadioField from 'app/components/RadioField';
import TextField from 'app/components/TextField';

const otherOpts = [
  { displayText: 'Organization', value: 'organization' },
  { displayText: 'Individual', value: 'individual' }
];

export const OtherClaimantForm = () => {
  const { register, watch } = useFormContext();
  const watchType = watch('type');

  return (
    <>
      <br />
      <RadioField
        name="type"
        label="Is the claimant an organization or individual?"
        inputRef={register}
        strongLabel
        vertical
        options={otherOpts}
      />
      { watchType === 'organization' &&
        <div style={{ marginTop: '26px' }}>
          <TextField
            name="organization"
            label="Organization name"
            strongLabel
          />
          <AddressForm />
          <TextField
            name="email"
            label="Claimant email"
            optional
            strongLabel
          />
          <TextField
            name="phoneNumber"
            label="Phone number"
            optional
            strongLabel
          />
          <RadioField
            name="vaForm"
            label="Do you have a VA Form 21-22 for this claimant?"
            inputRef={register}
            strongLabel
            vertical
            options={Constants.BOOLEAN_RADIO_OPTIONS}
          />
        </div>
      }
    </>
  );
};

export default OtherClaimantForm;
