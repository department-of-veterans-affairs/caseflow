import React, { useEffect, useState } from 'react';
import PropTypes from 'prop-types';

import { Controller, useFormContext } from 'react-hook-form';

import IndividualForm from './IndividualForm';
import SearchableDropdown from 'app/components/SearchableDropdown';
import OtherForm from './OtherForm';

const individual = ['spouse', 'child', 'individual'];

const relationshipOpts = [
  { label: 'Attorney (previously or currently)', value: 'attorney' },
  { label: 'Child', value: 'child' },
  { label: 'Spouse', value: 'spouse' },
  { label: 'Other', value: 'other' },
];

export const AddClaimantForm = ({ onSubmit }) => {
  const { control, handleSubmit, watch } = useFormContext();
  const watchRelationship = watch('relationship'); /* set in SearchableDropdown */
  const watchType = watch('type'); /* set in OtherForm */

  const renderIndividualForm = individual.includes(watchType || watchRelationship?.value);

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
      { watchRelationship?.value === 'other' && <OtherForm />}
      { renderIndividualForm && <IndividualForm /> }
    </form>
  );
};

AddClaimantForm.propTypes = {
  onSubmit: PropTypes.func
};

