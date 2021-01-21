import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import * as Constants from '../../constants';

import { Controller, useFormContext } from 'react-hook-form';

import SearchableDropdown from 'app/components/SearchableDropdown';
import IndividualForm from './IndividualForm'
import AddressForm from 'app/components/AddressForm'
import RadioField from 'app/components/RadioField';;
import TextField from 'app/components/TextField';

const relationshipOpts = [
  { label: 'Attorney (previously or currently)', value: 'attorney' },
  { label: 'Child', value: 'child' },
  { label: 'Spouse', value: 'spouse' },
  { label: 'Other', value: 'other' },
];

const otherOpts = [
  {displayText: 'Organization', value: 'organization'},
  {displayText: 'Individual', value: 'individual'}
];

// const radioOpts = useMemo(() => {
//     return [
//       ...otherOpts,
//     ];
//   }, [otherOpts]);


const individuals = ['spouse', 'child'];
const other = ['other']

// const handleOtherClaimant = (value) => {
//   debugger
//   if (value === "organization") {
//     return (
//       <div>
//         <TextField
//          name="organization" 
//          label="Organization name" 
//          strongLabel
//         />
//       </div>
//     );
//   } else {
//     return (
//       <IndividualForm />
//     )
//   }
// };

export const AddClaimantForm = ({ onSubmit }) => {
  const { control, handleSubmit, register, watch } = useFormContext();
  const watchRelationship = watch('relationship')
  const watchType = watch('type')
  

  const setOtherClaimant = () => {
    console.log("type", watchType)
    return (
      <div style={{ marginTop: '32px' }}>
        <RadioField
          name="type" 
          label="Is the claimant an organization or individual?"
          inputRef={register}
          strongLabel
          vertical
          options={otherOpts}
        />
      </div>
    );
  };

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      <Controller
        as={SearchableDropdown}
        control={control}
        label="Relationship to the Veteran"
        name="relationship"
        options={relationshipOpts}
        strongLabel
      />
      {individuals.includes(watchRelationship?.value) && <IndividualForm />}
      {other.includes(watchRelationship?.value) && setOtherClaimant()}
      {watchType == 'organization' && 
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
            name="phone number"
            label="Phone number"
            optional
            strongLabel
          />
          <RadioField
            options={Constants.BOOLEAN_RADIO_OPTIONS}
            vertical
            label="Do you have a VA Form 21-22 for this claimant?"
            name="21-22-radio"
          />
        </div>
      }
      {watchType == 'individual' &&
        <div>
          <IndividualForm />
        </div>
      }
    </form>
  );
};

AddClaimantForm.propTypes = {
  onSubmit: PropTypes.func
}; 

