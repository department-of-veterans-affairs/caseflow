import React from 'react';
import { useFormContext } from 'react-hook-form';
import PropTypes from 'prop-types';

import NonCompReportFilterContainer from 'app/nonComp/components/NonCompReportFilter';
import ReportPageDateSelector from 'app/nonComp/components/ReportPage/ReportPageDateSelector';

const TIMING_SPECIFIC_OPTIONS = [
  {
    label: 'After',
    value: 'after'
  },
  {
    label: 'Before',
    value: 'before'
  },
  {
    label: 'Between',
    value: 'between'
  },
  {
    label: 'Last 7 Days',
    value: 'last_7_days'
  },
  {
    label: 'Last 30 Days',
    value: 'last_30_days'
  },
  {
    label: 'Last 365 Days',
    value: 'last_365_days'
  },
];

export const TimingSpecification = () => {
  const { watch, control } = useFormContext();
  const watchTimingSpecification = watch('timingSpecifications');

  return (
    <div>
      <hr style={{ marginTop: '50px', marginBottom: '50px' }} />
      <NonCompReportFilterContainer
        header="Timing specifications"
        name="timingSpecifications"
        label="Range"
        options={TIMING_SPECIFIC_OPTIONS}
      />
      {
        ['after', 'before', 'between'].includes(watchTimingSpecification) ?
          <ReportPageDateSelector
            control={control}
            name={watchTimingSpecification === 'between' ? 'from' : 'date'}
            label={watchTimingSpecification === 'between' ? 'From' : 'Date'}
          /> :
          null
      }
      {
        watchTimingSpecification === 'between' ?
          <ReportPageDateSelector control={control}
            name="to"
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
