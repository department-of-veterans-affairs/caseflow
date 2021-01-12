import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';

import { Controller, useFormContext } from 'react-hook-form';

import SearchableDropdown from 'app/components/SearchableDropdown';
import { render } from 'react-dom';

const relationshipOpts = [
  { label: 'Attorney (previously or currently)', value: 'attorney' },
  { label: 'Child', value: 'child' },
  { label: 'Spouse', value: 'spouse' },
  { label: 'Other', value: 'other' },
];

export const AddClaimantForm = ({ onSubmit }) => {
  const { control, handleSubmit } = useFormContext();
  const [renderForm, setRenderForm] = useState(false);

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      <Controller
        as={SearchableDropdown}
        name="relationship"
        label="Relationship to the Veteran"
        options={relationshipOpts}
        control={control}
        strongLabel
        setRenderForm={setRenderForm}
        addClaimantForm
      />
      {
        renderForm && <h1>HI</h1>
      }
    </form>
  );
};

AddClaimantForm.propTypes = {
  onSubmit: PropTypes.func,
};
