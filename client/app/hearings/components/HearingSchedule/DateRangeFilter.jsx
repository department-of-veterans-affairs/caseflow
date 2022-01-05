import React from 'react';
import PropTypes from 'prop-types';
import BasicDateRangeSelector from 'app/components/BasicDateRangeSelector';
import InlineForm from 'app/components/InlineForm';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import COPY from '../../../../COPY.json';
import { css } from 'glamor';

export const dateSearchStyles = css({
  marginTop: '50px'
});

const DateRangeFilter = ({ startDateChange, endDateChange, startDateValue, endDateValue, onApply }) => (
  <InlineForm>
    <BasicDateRangeSelector
      startDateName="fromDate"
      startDateValue={startDateValue}
      startDateLabel={COPY.HEARING_SCHEDULE_VIEW_START_DATE_LABEL}
      endDateName="toDate"
      endDateValue={endDateValue}
      endDateLabel={COPY.HEARING_SCHEDULE_VIEW_END_DATE_LABEL}
      onStartDateChange={startDateChange}
      onEndDateChange={endDateChange}
    />
    <div {...dateSearchStyles}>
      <Link
        name="apply"
        to="/schedule"
        onClick={onApply}>
        {COPY.HEARING_SCHEDULE_VIEW_PAGE_APPLY_LINK}
      </Link>
    </div>
  </InlineForm>
);

DateRangeFilter.propTypes = {
  startDateChange: PropTypes.func,
  endDateChange: PropTypes.func,
  startDateValue: PropTypes.func,
  endDateValue: PropTypes.func,
  onApply: PropTypes.func,
};

export default DateRangeFilter;
