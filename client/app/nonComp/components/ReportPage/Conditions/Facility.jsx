import React from 'react';
import PropTypes from 'prop-types';
import { Controller, useFormContext } from 'react-hook-form';
import { get } from 'lodash';
import * as yup from 'yup';
import SearchableDropdown from 'app/components/SearchableDropdown';
import BGS_FACILITY_CODES from 'app/../constants/BGS_FACILITY_CODES';
import * as ERRORS from 'constants/REPORT_PAGE_VALIDATION_ERRORS';

export const facilitySchema = yup.object({
  facilityCodes: yup.array().min(1, ERRORS.SELECT_ONE_DROPDOWN)
});

// Convert to array and sort alphabetically by label
const formattedFacilityCodes = Object.entries(BGS_FACILITY_CODES).map((facility) => {
  return {
    value: facility[0],
    label: facility[1]
  };
}).
  sort((stringA, stringB) => stringA.label.localeCompare(stringB.label));

export const Facility = ({ control, field, name }) => {
  const { errors } = useFormContext();

  const fieldName = `${name}.options.facilityCodes`;

  return (
    <div className="report-page-multi-select-dropdown">
      <Controller
        control={control}
        name={fieldName}
        defaultValue={field.options.facilityCodes ?? []}
        render={({ onChange, ref, ...rest }) => (
          <SearchableDropdown
            {...rest}
            errorMessage={get(errors, fieldName)?.message}
            inputRef={ref}
            label="Facility Type"
            multi
            onChange={onChange}
            options={formattedFacilityCodes}
          />
        )}
      />
    </div>
  );
};

Facility.propTypes = {
  control: PropTypes.object,
  field: PropTypes.object,
  name: PropTypes.string,
};
