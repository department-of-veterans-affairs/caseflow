// actions
//
export const HANDLE_DOCKET_SERVER_ERROR = 'HANDLE_DOCKET_SERVER_ERROR';
export const HANDLE_WORKSHEET_SERVER_ERROR = 'HANDLE_WORKSHEET_SERVER_ERROR';

export const POPULATE_UPCOMING_HEARINGS = 'POPULATE_UPCOMING_HEARINGS';
export const POPULATE_DAILY_DOCKET = 'POPULATE_DAILY_DOCKET';

export const SET_REPNAME = 'SET_REPNAME';
export const SET_WITNESS = 'SET_WITNESS';

export const SET_NOTES = 'SET_NOTES';
export const SET_DISPOSITION = 'SET_DISPOSITION';
export const SET_HOLD_OPEN = 'SET_HOLD_OPEN';
export const SET_AOD = 'SET_AOD';
export const SET_TRANSCRIPT_REQUESTED = 'SET_TRANSCRIPT_REQUESTED';
export const SET_EVIDENCE_WINDOW_WAIVED = 'SET_EVIDENCE_WINDOW_WAIVED';
export const SET_HEARING_VIEWED = 'SET_HEARING_VIEWED';
export const SET_HEARING_PREPPED = 'SET_HEARING_PREPPED';

export const POPULATE_WORKSHEET = 'POPULATE_WORKSHEET';
export const FETCHING_WORKSHEET = 'FETCHING_WORKSHEET';

export const SELECT_DOCKETS_PAGE_TAB_INDEX = 'SELECT_DOCKETS_PAGE_TAB_INDEX';

// issues
export const SET_DESCRIPTION = 'SET_DESCRIPTION';
export const SET_ISSUE_NOTES = 'SET_ISSUE_NOTES';
export const SET_WORKSHEET_ISSUE_NOTES = 'SET_WORKSHEET_ISSUE_NOTES';
export const SET_ISSUE_DISPOSITION = 'SET_ISSUE_DISPOSITION';
export const SET_REOPEN = 'SET_REOPEN';
export const SET_ALLOW = 'SET_ALLOW';
export const SET_DENY = 'SET_DENY';
export const SET_REMAND = 'SET_REMAND';
export const SET_DISMISS = 'SET_DISMISS';
export const SET_OMO = 'SET_OMO';
export const ADD_ISSUE = 'ADD_ISSUE';
export const DELETE_ISSUE = 'DELETE_ISSUE';
export const TOGGLE_ISSUE_DELETE_MODAL = 'TOGGLE_ISSUE_DELETE_MODAL';

export const SET_MILITARY_SERVICE = 'SET_MILITARY_SERVICE';
export const SET_SUMMARY = 'SET_SUMMARY';

export const TOGGLE_DOCKET_SAVING = 'TOGGLE_DOCKET_SAVING';
export const TOGGLE_WORKSHEET_SAVING = 'TOGGLE_WORKSHEET_SAVING';

export const SET_WORKSHEET_TIME_SAVED = 'SET_WORKSHEET_TIME_SAVED';
export const SET_DOCKET_TIME_SAVED = 'SET_DOCKET_TIME_SAVED';

export const SET_DOCKET_SAVE_FAILED = 'SET_DOCKET_SAVE_FAILED';
export const SET_ISSUE_EDITED_FLAG_TO_FALSE = 'SET_ISSUE_EDITED_FLAG_TO_FALSE';
export const SET_WORKSHEET_SAVE_FAILED_STATUS = 'SET_WORKSHEET_SAVE_FAILED_STATUS';

export const SET_WORKSHEET_EDITED_FLAG_TO_FALSE = 'SET_WORKSHEET_EDITED_FLAG_TO_FALSE';
export const SET_EDITED_FLAG_TO_FALSE = 'SET_EDITED_FLAG_TO_FALSE';

export const DISPOSITION_OPTIONS = [{ value: 'held',
  label: 'Held' },
{ value: 'no_show',
  label: 'No Show' },
{ value: 'cancelled',
  label: 'Cancelled' },
{ value: 'postponed',
  label: 'Postponed' }];

export const SERVER_ERROR_CODES = {
  VACOLS_RECORD_DOES_NOT_EXIST: 1001
};

export const VIDEO_HEARING = 'Video';
export const CENTRAL_OFFICE_HEARING = 'Central';

export const TIME_OPTIONS = [{
  value: '8:30',
  label: '8:30 am ' },
{ value: '9:00',
  label: '9:00 am ' },
{ value: '9:30',
  label: '9:30 am ' },
{ value: '10:00',
  label: '10:00 am ' },
{ value: '10:30',
  label: '10:30 am ' },
{ value: '11:00',
  label: '11:00 am ' },
{ value: '11:30',
  label: '11:30 am ' },
{ value: '12:00',
  label: '12:00 pm ' },
{ value: '12:30',
  label: '12:30 pm ' },
{ value: '13:00',
  label: '1:00 pm ' },
{ value: '13:30',
  label: '1:30 pm ' },
{ value: '14:00',
  label: '2:00 pm ' },
{ value: '14:30',
  label: '2:30 pm ' },
{ value: '15:00',
  label: '3:00 pm ' },
{ value: '15:30',
  label: '3:30 pm ' },
{ value: '16:00',
  label: '4:00 pm ' },
{ value: '16:30',
  label: '4:30 pm '
}];
