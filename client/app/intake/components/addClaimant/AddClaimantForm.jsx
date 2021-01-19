import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';

import { Controller, useFormContext } from 'react-hook-form';

import SearchableDropdown from 'app/components/SearchableDropdown';
import IndividualForm from './IndividualForm'
import RadioField from 'app/components/RadioField';;

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

const handleOtherClaimant = (value) => {
  debugger
  console.log(value)
}



export const AddClaimantForm = ({ onSubmit }) => {
  const { control, handleSubmit } = useFormContext();
  const [relationship, setRelationship] = useState(null);

  const otherClaimant = () => {
    return (
      <div style={{ marginTop: '32px' }}>
        <RadioField
          name="other claimant"
          label="Is the claimant an organization or individual?"
          strongLabel
          vertical
          options={otherOpts}
          onChange={handleOtherClaimant}
        />
      </div>
    );
  };

  useEffect(() => {
    console.log("RELATIONSHIP", relationship);
  }, [relationship]);

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      <Controller
        as={SearchableDropdown}
        control={control}
        label="Relationship to the Veteran"
        name="relationship"
        setRelationship={setRelationship}
        options={relationshipOpts}
        strongLabel
        value={relationship}
      />
      {individuals.includes(relationship) && <IndividualForm />}
      {other.includes(relationship) && otherClaimant()}
    </form>
  );
};

AddClaimantForm.propTypes = {
  onSubmit: PropTypes.func,
}; 

