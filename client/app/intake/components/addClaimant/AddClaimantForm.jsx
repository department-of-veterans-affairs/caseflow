import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';

import { Controller, useFormContext } from 'react-hook-form';

import SearchableDropdown from 'app/components/SearchableDropdown';
import DependantForm from './DependantForm'
import RadioField from 'app/components/RadioField';;

const relationshipOpts = [
  { label: 'Attorney (previously or currently)', value: 'attorney' },
  { label: 'Child', value: 'child' },
  { label: 'Spouse', value: 'spouse' },
  { label: 'Other', value: 'other' },
];

const dependants = ['spouse', 'child'];

export const AddClaimantForm = ({ onSubmit }) => {
  const { control, handleSubmit } = useFormContext();
  const [relationship, setRelationship] = useState(null);

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
      {dependants.includes(relationship) && <DependantForm />}
    </form>
  );
};

AddClaimantForm.propTypes = {
  onSubmit: PropTypes.func,
};
