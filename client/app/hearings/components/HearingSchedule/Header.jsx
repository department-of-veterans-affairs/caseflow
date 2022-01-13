import React from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

import COPY from '../../../../COPY';
import { LIST_SCHEDULE_VIEWS } from 'app/hearings/constants';
import DateRangeFilter, { dateSearchStyles } from 'app/hearings/components/HearingSchedule/DateRangeFilter';
import { SwitchViewDropdown } from 'app/hearings/components/HearingSchedule/SwitchView';
import { CSVButton } from 'app/hearings/components/HearingSchedule/CSVLink';

const inlineFormStyling = css({
  marginBottom: 44,
  display: 'flex',
  alignItems: 'flex-end',
  '> div': {
    ' & .cf-inline-form': {
      lineHeight: '2em',
      marginTop: 0
    },
    '& .question-label': {
      marginLeft: 0,
      paddingLeft: 0
    },
    '& .cf-form-textinput': {
      marginTop: 0,
      marginLeft: 0,
      marginRight: 30
    },
    '& input': {
      marginRight: 0
    },
    '& label': {
      marginLeft: 0
    }
  }
});

const dateRangeStyling = css({
  display: 'flex',
  flex: 1
});

const viewButtonStyling = css({
  marginBottom: 5
});

const actionButtonsStyling = css({
  marginLeft: 25,
  marginRight: 0
});

export const HearingScheduleHeader = ({
  user,
  view,
  switchListView,
  startDate,
  onViewStartDateChange,
  endDate,
  onViewEndDateChange,
  setDateRange,
  fileName,
  headers
}) => {
  let title = COPY.HEARING_SCHEDULE_VIEW_PAGE_HEADER;

  if (user.userCanViewHearingSchedule || user.userCanVsoHearingSchedule) {
    title = COPY.HEARING_SCHEDULE_VIEW_PAGE_HEADER_NONBOARD_USER;
  } else if (user.userHasHearingPrepRole) {
    title = view === LIST_SCHEDULE_VIEWS.DEFAULT_VIEW ?
      COPY.HEARING_SCHEDULE_JUDGE_DEFAULT_VIEW_PAGE_HEADER :
      COPY.HEARING_SCHEDULE_JUDGE_SHOW_ALL_VIEW_PAGE_HEADER;
  }

  return (
    <React.Fragment>
      <h1 className="cf-push-left">{title}</h1>
      <div className="cf-push-right">
        {user.userCanBuildHearingSchedule && (
          <React.Fragment>
            <span className="cf-push-left">
              <Link button="secondary" to="/schedule/add_hearing_day">Add Hearing Day</Link>
            </span>
            <span className="cf-push-left" {...actionButtonsStyling}>
              <Link button="secondary" to="/schedule/build">Build Schedule</Link>
            </span>
          </React.Fragment>
        )}
        {user.userCanAssignHearingSchedule && (
          <span {...actionButtonsStyling}>
            <Link button="primary" to="/schedule/assign">Schedule Veterans</Link>
          </span>
        )}
      </div>
      <div className="cf-help-divider" {...dateSearchStyles} />
      <div {...inlineFormStyling} >
        <div {...dateRangeStyling}>
          <DateRangeFilter
            startDateValue={startDate}
            startDateChange={onViewStartDateChange}
            endDateValue={endDate}
            endDateChange={onViewEndDateChange}
            onApply={setDateRange}
          />
        </div>
        <div {...viewButtonStyling}>
          {user.userHasHearingPrepRole && <SwitchViewDropdown onSwitchView={switchListView} />}
          <CSVButton view={view} startDate={startDate} endDate={endDate} fileName={fileName} headers={headers} />
        </div>
      </div>
    </React.Fragment>
  );
};

HearingScheduleHeader.propTypes = {
  history: PropTypes.object,
  user: PropTypes.object,
  headers: PropTypes.object,
  view: PropTypes.string,
  fileName: PropTypes.string,
  switchListView: PropTypes.func,
  startDate: PropTypes.string,
  onViewStartDateChange: PropTypes.func,
  endDate: PropTypes.string,
  onViewEndDateChange: PropTypes.func,
  setDateRange: PropTypes.func
};
