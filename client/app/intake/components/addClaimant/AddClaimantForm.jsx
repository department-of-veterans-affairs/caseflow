import React from 'react';
import PropTypes from 'prop-types';

import { Controller, useFormContext } from 'react-hook-form';

import SearchableDropdown from 'app/components/SearchableDropdown';

const relationshipOpts = [
  { label: 'Attorney (previously or currently)', value: 'attorney' },
  { label: 'Child', value: 'child' },
  { label: 'Spouse', value: 'spouse' },
  { label: 'Other', value: 'other' },
];

export const AddClaimantForm = ({ onSubmit }) => {
  const { control, handleSubmit } = useFormContext();

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      <Controller
        as={SearchableDropdown}
        name="relationship"
        label="Relationship to the Veteran"
        options={relationshipOpts}
        control={control}
      />
    </form>
  );
};

AddClaimantForm.propTypes = {
  onSubmit: PropTypes.func,
};
