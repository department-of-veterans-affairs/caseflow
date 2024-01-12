import React from 'react';
import { Controller, useFormContext } from 'react-hook-form';
import PropTypes from 'prop-types';

import SearchableDropdown from 'app/components/SearchableDropdown';

const RHFControlledDropdown = ({ control, ...props }) => (
  <>
    <h2>{ props.header }</h2>
    <Controller
      control={control}
      name={props.name}
      render={({ onChange, ...rest }) => (
        <SearchableDropdown
          {...rest}
          name={props.name}
          label={props.label}
          options={props.options}
          searchable={false}
          onChange={(valObj) => {
            onChange(valObj?.value);
          }}
          required={props.required}
          optional={props.optional}
        />
      )}
    />
  </>
);

export const RHFControlledDropdownContainer = (props) => {
  const methods = useFormContext();

  return <RHFControlledDropdown {...methods} {...props} />;
};

RHFControlledDropdown.propTypes = {
  control: PropTypes.object,
  header: PropTypes.string,
  name: PropTypes.string,
  label: PropTypes.string,
  options: PropTypes.array,
  optional: PropTypes.bool,
  required: PropTypes.bool
};

export default RHFControlledDropdownContainer;
