import React from 'react';
import { Controller, useFormContext } from 'react-hook-form';
import PropTypes from 'prop-types';

import SearchableDropdown from '../../components/SearchableDropdown';

const NonCompReportFilter = ({ control, props }) => (
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
          required={false}
        />
      )}
    />
  </>
);

export const NonCompReportFilterContainer = (props) => {
  const methods = useFormContext();

  return <NonCompReportFilter {...methods} props={props} />;
};

NonCompReportFilter.propTypes = {
  control: PropTypes.object,
  props: PropTypes.object,
  header: PropTypes.string,
  name: PropTypes.string,
  label: PropTypes.string,
  options: PropTypes.array
};

NonCompReportFilterContainer.propTypes = {
  props: PropTypes.object
};

export default NonCompReportFilterContainer;
