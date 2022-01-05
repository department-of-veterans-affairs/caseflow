import React from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import { CSVLink } from 'react-csv';

import COPY from '../../../../COPY.json';
import { LIST_SCHEDULE_VIEWS } from 'app/hearings/constants';
import DateRangeFilter, { dateSearchStyles } from 'app/hearings/components/HearingSchedule/DateRangeFilter';
import { SwitchViewDropdown } from 'app/hearings/components/HearingSchedule/SwitchView';
import Button from 'app/components/Button';

const inlineFormStyling = css({
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

const viewButtonStyling = css({
  display: 'flex',
  flex: 1
});

const actionButtonsStyling = css({
  marginRight: '25px',
});

export const HearingScheduleHeader = ({
  history,
  user,
  view,
  switchListView,
  startDate,
  onViewStartDateChange,
  endDate,
  onViewEndDateChange,
  setDateRangeKey,
  fileName
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
        {user.userCanAssignHearingSchedule && (
          <span className="cf-push-left" {...actionButtonsStyling}>
            <Link button="primary" to="/schedule/assign">Schedule Veterans</Link>
          </span>
        )}
        {user.userCanBuildHearingSchedule && (
          <span className="cf-push-left">
            <Link button="secondary" to="/schedule/build">Build Schedule</Link>
          </span>
        )}
      </div>
      <div className="cf-help-divider" {...dateSearchStyles} />
      <div {...inlineFormStyling} >
        <div {...viewButtonStyling}>
          <DateRangeFilter
            startDateValue={startDate}
            startDateChange={onViewStartDateChange}
            endDateValue={endDate}
            endDateChange={onViewEndDateChange}
            onApply={setDateRangeKey}
          />
        </div>
        <div>
          {user.userHasHearingPrepRole && <SwitchViewDropdown onSwitchView={switchListView} />}
          <SwitchViewDropdown onSwitchView={switchListView} />
          <CSVLink data={[]} headers={[]} target="_blank" filename={fileName} >
            <Button classNames={['usa-button-secondary']}>Download current view</Button>
          </CSVLink>
        </div>
      </div>
      {user.userCanBuildHearingSchedule && (
        <Button linkStyling onClick={() => history.push('/schedule/add_hearing_day')}>Add Hearing Day</Button>
      )}
    </React.Fragment>
  );
};

HearingScheduleHeader.propTypes = {
  history: PropTypes.object,
  user: PropTypes.object,
  view: PropTypes.string,
  switchListView: PropTypes.func,
  startDate: PropTypes.string,
  onViewStartDateChange: PropTypes.func,
  endDate: PropTypes.string,
  onViewEndDateChange: PropTypes.func,
  setDateRangeKey: PropTypes.func
};
