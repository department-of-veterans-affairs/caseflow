import React from 'react';
import BasicDateRangeSelector from '../../components/BasicDateRangeSelector';
import InlineForm from '../../components/InlineForm';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import COPY from '../../../COPY.json';
import { css } from 'glamor';

export const hearingSchedStyling = css({
  marginTop: '50px'
});


const downloadButtonStyling = css({
  marginTop: '60px'
});


const inlineFormStyling = css({
  '> div': {
    ' & .cf-inline-form': {
      lineHeight: '2em',
      marginTop: '20px'
    },
    '& .question-label': {
      paddingLeft: 0
    },
    '& .cf-form-textinput': {
      marginTop: 0,
      marginRight: 30
    },
    '& input': {
      marginRight: 0
    }
  }
});


const ListScheduleDateSearch = ({ onApply, filteredByList, clearFilteredByList, startDateChange, endDateChange, startDateValue, endDateValue}) => (
  <div className="cf-push-left" {...inlineFormStyling} >
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
      <div {...hearingSchedStyling}>
        <Link
          name="apply"
          to="/schedule"
          onClick={onApply}>
          {COPY.HEARING_SCHEDULE_VIEW_PAGE_APPLY_LINK}
        </Link>
      </div>
    </InlineForm>
  </div>
);

export default ListScheduleDateSearch;
