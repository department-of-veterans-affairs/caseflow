import React from 'react';
import { Controller, useFormContext } from 'react-hook-form';
import PropTypes from 'prop-types';

import SearchableDropdown from '../../components/SearchableDropdown';
import REPORT_TYPE_CONSTANTS from '../../../constants/REPORT_TYPE_CONSTANTS.json'

const NonCompReportFilter = ({ control }) => (
  <>
    <h2>Type of Report</h2>
    <Controller
      control={control}
      name="reportType"
      render={({ onChange, ref, ...rest }) => (
        <SearchableDropdown
          {...rest}
          name="reportType"
          label="Report Type"
          options={REPORT_TYPE_CONSTANTS.REPORT_TYPE_OPTIONS}
          searchable={false}
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
};

export default NonCompReportFilterContainer;
