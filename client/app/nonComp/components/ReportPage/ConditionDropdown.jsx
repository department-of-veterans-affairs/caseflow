import React, { useState } from 'react';
import SearchableDropdown from 'app/components/SearchableDropdown';
import { Controller } from 'react-hook-form';
import PropTypes from 'prop-types';

export const ConditionDropdown = ({ control, determineOptions, name }) => {
  let [disabled, setDisabled] = useState(false);

  const filteredOptions = determineOptions();

  return <Controller
    control={control}
    name={name}
    defaultValue={null}
    render={({ onChange, ...rest }) => (
      <SearchableDropdown
        {...rest}
        label="Variable"
        options={filteredOptions}
        readOnly={disabled}
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
  determineOptions: PropTypes.func,
  name: PropTypes.string
};
