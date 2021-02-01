import React from 'react';
import PropTypes from 'prop-types';
import { Controller, useFormContext } from 'react-hook-form';

// import IndividualForm from './IndividualForm';
import SearchableDropdown from 'app/components/SearchableDropdown';
// import OtherClaimantForm from './OtherClaimantForm';

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
  const watchType = watch('type'); /* set in OtherClaimantForm */

  const renderIndividualForm = individual.includes(watchType || watchRelationship?.value);

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      <Controller
        control={control}
        name="relationship"
        label="Relationship to the Veteran"
        options={relationshipOpts}
        strongLabel
        as={SearchableDropdown}
      />
      { watchRelationship?.value === 'other' && <OtherClaimantForm />}
      { renderIndividualForm && <IndividualForm /> }
    </form>
  );
};

AddClaimantForm.propTypes = {
  onSubmit: PropTypes.func
};

