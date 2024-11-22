import React, { useState } from 'react';
import SearchableDropdown from 'app/components/SearchableDropdown';
import { Controller, useFormContext } from 'react-hook-form';
import PropTypes from 'prop-types';
import { get } from 'lodash';

export const ConditionDropdown = ({ control, filteredOptions, name, field }) => {
  let [disabled, setDisabled] = useState(false);

  const dropdownName = `${name}.condition`;
  const { errors } = useFormContext();

  return <Controller
    control={control}
    name={dropdownName}
    defaultValue={field.condition}
    render={({ onChange, ref, ...rest }) => (
      <SearchableDropdown
        {...rest}
        label="Variable"
        options={filteredOptions}
        readOnly={disabled}
        inputRef={ref}
        errorMessage={get(errors, dropdownName)?.message}
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
