import React from 'react';
import { Controller, useFormContext } from 'react-hook-form';

import SearchableDropdown from '../../components/SearchableDropdown';
import COPY from '../../../COPY';

const NonCompReportFilter = ({ control }) => (
  <>
    <h2>Type of Report</h2>
    <Controller
      control={control}
      name='reportType'
      render={({ onChange, ref, ...rest }) => (
        <SearchableDropdown
          inputRef={ref}
          {...rest}
          name='reportType'
          label='Report Type'
          options={COPY.VHA_REPORT_TYPE_OPTIONS}
          searchable={false}
          onChange={(valObj) => onChange(valObj?.value)}
          defaultValue=''
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
  control: PropTypes.node,
};

export default NonCompReportFilterContainer;
