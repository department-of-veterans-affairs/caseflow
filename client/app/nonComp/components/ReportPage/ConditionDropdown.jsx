import React, { useState } from 'react';
import SearchableDropdown from 'app/components/SearchableDropdown';
import { Controller } from 'react-hook-form';
import PropTypes from 'prop-types';

export const ConditionDropdown = ({ control, filteredOptions, name, errors }) => {
  let [disabled, setDisabled] = useState(false);

  const dropdownName = `${name}.condition`;

  return <Controller
    control={control}
    name={dropdownName}
    defaultValue={null}
    render={({ onChange, ...rest }) => (
      <SearchableDropdown
        {...rest}
        label="Variable"
        options={filteredOptions}
        readOnly={disabled}
        errorMessage={errors?.condition?.message ?? ''}
        onChange={(valObj) => {
          setDisabled(true);
          onChange(valObj?.value);
        }}
        placeholder="Select a variable"
      />
    )}
  />;
};

ConditionDropdown.propTypes = {
  control: PropTypes.object,
  filteredOptions: PropTypes.array,
  name: PropTypes.string,
  errors: PropTypes.object
};
