import React from 'react';
import { useFormContext } from 'react-hook-form';
import PropTypes from 'prop-types';

import RHFControlledDropdownContainer from 'app/nonComp/components/ReportPage/RHFControlledDropdown';
import ReportPageDateSelector from 'app/nonComp/components/ReportPage/ReportPageDateSelector';

import { TIMING_SPECIFIC_OPTIONS } from 'constants/REPORT_TYPE_CONSTANTS';
import { format, add } from 'date-fns';

import * as ERRORS from 'constants/REPORT_PAGE_VALIDATION_ERRORS';

import * as yup from 'yup';

export const timingSchema = yup.lazy((value) => {
  // eslint-disable-next-line no-undefined
  if (value !== undefined) {
    return yup.object({
      startDate: yup.date().
        when('range', {
          is: (range) => ['after', 'before', 'between'].includes(range),
          then: yup.date().typeError(ERRORS.MISSING_DATE).
            max(format(add(new Date(), { hours: 1 }), 'MM/dd/yyyy'), ERRORS.DATE_FUTURE),
          otherwise: (schema) => schema.notRequired()
        }),
      endDate: yup.date().
        when('range', {
          is: 'between',
          then: yup.date().typeError(ERRORS.MISSING_DATE).
            max(format(add(new Date(), { hours: 1 }), 'MM/dd/yyyy'), ERRORS.DATE_FUTURE).
            min(yup.ref('startDate'), ERRORS.END_DATE_SMALL),
          otherwise: (schema) => schema.notRequired()
        })
    });
  }

  return yup.mixed().notRequired();
});

export const TimingSpecification = () => {
  const { watch, control, formState } = useFormContext();
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
        errorMessage={formState?.errors?.timing?.range?.message}
      />
      {
        ['after', 'before', 'between'].includes(watchTimingSpecification) ?
          <ReportPageDateSelector
            control={control}
            name="timing.startDate"
            label={isTimingsSpecificationBetween ? 'From' : 'Date'}
            errorMessage={formState?.errors?.timing?.startDate?.message}
          /> :
          null
      }
      {
        isTimingsSpecificationBetween ?
          <ReportPageDateSelector control={control}
            name="timing.endDate"
            label="To"
            errorMessage={formState?.errors?.timing?.endDate?.message}
          /> :
          null
      }
    </div>
  );
};

TimingSpecification.propTypes = {
  control: PropTypes.object,
  watchTimingSpecification: PropTypes.string
};
export default TimingSpecification;
