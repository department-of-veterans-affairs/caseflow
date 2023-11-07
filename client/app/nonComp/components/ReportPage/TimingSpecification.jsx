import React from 'react';
import { useFormContext } from 'react-hook-form';
import PropTypes from 'prop-types';

import RHFControlledDropdownContainer from 'app/nonComp/components/ReportPage/RHFControlledDropdown';
import ReportPageDateSelector from 'app/nonComp/components/ReportPage/ReportPageDateSelector';

import { TIMING_SPECIFIC_OPTIONS } from 'constants/REPORT_TYPE_CONSTANTS';

export const TimingSpecification = () => {
  const { watch, control } = useFormContext();
  const watchTimingSpecification = watch('timing.range');
  const isTimingsSpecificationBetween = watchTimingSpecification === 'between';

  return (
    <div>
      <hr style={{ marginTop: '50px', marginBottom: '50px' }} />
      <RHFControlledDropdownContainer
        header="Timing specifications"
        name="timing.range"
        label="Range"
        options={TIMING_SPECIFIC_OPTIONS}
        optional
      />
      {
        ['after', 'before', 'between'].includes(watchTimingSpecification) ?
          <ReportPageDateSelector
            control={control}
            name="timing.start_date"
            label={isTimingsSpecificationBetween ? 'From' : 'Date'}
          /> :
          null
      }
      {
        isTimingsSpecificationBetween ?
          <ReportPageDateSelector control={control}
            name="timing.end_date"
            label="To" /> : null
      }
    </div>
  );
};

TimingSpecification.propTypes = {
  control: PropTypes.object,
  watchTimingSpecification: PropTypes.string
};
export default TimingSpecification;
