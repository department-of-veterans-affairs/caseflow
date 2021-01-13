import React, { useState } from 'react';
import PropTypes from 'prop-types';

import { Controller, useFormContext } from 'react-hook-form';

import TextField from 'app/components/TextField';
import SearchableDropdown from 'app/components/SearchableDropdown';

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
        renderForm && (<div style={{ marginTop: '20px' }}>
          <br />
          <TextField
            name="First name"
            strongLabel
          />
          <TextField
            name="Middle name/Initial"
            strongLabel
            optional
          />
          <TextField
            name="Last name"
            strongLabel
            optional
          />
          <TextField
            name="Suffix"
            strongLabel
            optional
          />

        </div>)
      }
    </form>
  );
};

AddClaimantForm.propTypes = {
  onSubmit: PropTypes.func,
};
