import React from 'react';
import { Controller, useFormContext } from 'react-hook-form';
import PropTypes from 'prop-types';

import SearchableDropdown from 'app/components/SearchableDropdown';
import REPORT_TYPE_CONSTANTS from 'constants/REPORT_TYPE_CONSTANTS';
import * as ERRORS from 'constants/REPORT_PAGE_VALIDATION_ERRORS';

import * as yup from 'yup';

export const reportTypeSchema = yup.string().
  oneOf(REPORT_TYPE_CONSTANTS.REPORT_TYPE_OPTIONS.map((opt) => opt.value), ERRORS.MISSING_SELECTION);

const NonCompReportFilter = ({ control, formState }) => (
  <>
    <h2>Type of report</h2>
    <Controller
      control={control}
      name="reportType"
      render={({ onChange, ref, ...rest }) => (
        <SearchableDropdown
          {...rest}
          label="Report Type"
          options={REPORT_TYPE_CONSTANTS.REPORT_TYPE_OPTIONS}
          searchable={false}
          inputRef={ref}
          errorMessage={formState.errors?.reportType?.message}
          onChange={(valObj) => onChange(valObj?.value)}
        />
      )}
    />
  </>
);

export const NonCompReportFilterContainer = () => {
  const methods = useFormContext();

  return <NonCompReportFilter {...methods} />;
};

NonCompReportFilter.propTypes = {
  control: PropTypes.object,
  formState: PropTypes.object
};

export default NonCompReportFilterContainer;
