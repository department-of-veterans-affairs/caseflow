import React from 'react';
import { Controller, useFormContext } from 'react-hook-form';
import PropTypes from 'prop-types';

import SearchableDropdown from 'app/components/SearchableDropdown';
import REPORT_TYPE_CONSTANTS from 'constants/REPORT_TYPE_CONSTANTS';

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
