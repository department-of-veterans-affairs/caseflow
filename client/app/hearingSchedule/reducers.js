/* eslint-disable max-lines */
import { timeFunction } from '../util/PerfDebug';
import { ACTIONS } from './constants';
import { update } from '../util/ReducerUtil';
import { combineReducers } from 'redux';

import commonComponentsReducer from '../components/common/reducers';
import caseListReducer from '../queue/CaseList/CaseListReducer';
import { workQueueReducer } from '../queue/reducers';
import uiReducer from '../queue/uiReducer/uiReducer';

export const initialState = {};
const hearingScheduleReducer = (state = initialState, action = {}) => {
  switch (action.type) {
  case ACTIONS.RECEIVE_HEARING_SCHEDULE:
    return update(state, {
      hearingSchedule: {
        $set: action.payload.hearingSchedule
      }
    });
  case ACTIONS.RECEIVE_PAST_UPLOADS:
    return update(state, {
      pastUploads: {
        $set: action.payload.pastUploads
      }
    });
  case ACTIONS.RECEIVE_SCHEDULE_PERIOD:
    return update(state, {
      schedulePeriod: {
        $set: action.payload.schedulePeriod
      }
    });
  case ACTIONS.RECEIVE_DAILY_DOCKET:
    return update(state, {
      dailyDocket: { $set: action.payload.dailyDocket },
      hearings: { $set: action.payload.hearings },
      hearingDayOptions: { $set: action.payload.hearingDayOptions }
    });
  case ACTIONS.RECEIVE_SAVED_HEARING:
    return update(state, {
      hearings: {
        [action.payload.hearing.id]: {
          $set: action.payload.hearing
        }
      },
      saveSuccessful: { $set: action.payload.hearing }
    });
  case ACTIONS.RESET_SAVE_SUCCESSFUL:
    return update(state, {
      $unset: ['saveSuccessful', 'displayLockSuccessMessage']
    });
  case ACTIONS.CANCEL_HEARING_UPDATE:
    return update(state, {
      hearings: {
        [action.payload.hearing.id]: {
          $unset: [
            'editedNotes',
            'editedDisposition',
            'editedDate',
            'editedTime',
            'editedOptionalTime',
            'editedRegionalOffice',
            'editedLocation',
            'edited'
          ] }
      }
    });
  case ACTIONS.RECEIVE_UPCOMING_HEARING_DAYS:
    return update(state, {
      upcomingHearingDays: {
        $set: action.payload.upcomingHearingDays
      }
    });
  case ACTIONS.RECEIVE_APPEALS_READY_FOR_HEARING:
    return update(state, {
      appealsReadyForHearing: {
        $set: action.payload.appeals
      }
    });
  case ACTIONS.HEARING_NOTES_UPDATE:
    return update(state, {
      hearings: {
        [action.payload.hearingId]: {
          editedNotes: { $set: action.payload.notes },
          edited: { $set: true }
        }
      }
    });
  case ACTIONS.TRANSCRIPT_REQUESTED_UPDATE:
    return update(state, {
      hearings: {
        [action.payload.hearingId]: {
          editedTranscriptRequested: { $set: action.payload.transcriptRequested },
          edited: { $set: true }
        }
      }
    });
  case ACTIONS.HEARING_DISPOSITION_UPDATE:
    return update(state, {
      hearings: {
        [action.payload.hearingId]: {
          editedDisposition: { $set: action.payload.disposition },
          edited: { $set: true }
        }
      }
    });
  case ACTIONS.HEARING_LOCATION_UPDATE:
    return update(state, {
      hearings: {
        [action.payload.hearingId]: {
          editedLocation: { $set: action.payload.location },
          edited: { $set: true }
        }
      }
    });
  case ACTIONS.HEARING_REGIONAL_OFFICE_UPDATE:
    return update(state, {
      hearings: {
        [action.payload.hearingId]: {
          editedRegionalOffice: { $set: action.payload.regionalOffice },
          edited: { $set: true }
        }
      }
    });
  case ACTIONS.HEARING_DATE_UPDATE:
    return update(state, {
      hearings: {
        [action.payload.hearingId]: {
          editedDate: { $set: action.payload.date },
          edited: { $set: true }
        }
      }
    });
  case ACTIONS.HEARING_TIME_UPDATE:
    return update(state, {
      hearings: {
        [action.payload.hearingId]: {
          editedTime: { $set: action.payload.time },
          edited: { $set: true }
        }
      }
    });
  case ACTIONS.HEARING_OPTIONAL_TIME:
    return update(state, {
      hearings: {
        [action.payload.hearingId]: {
          editedOptionalTime: { $set: action.payload.optionalTime },
          edited: { $set: true }
        }
      }
    });

  case ACTIONS.INVALID_FORM:
    return update(state, {
      hearings: {
        [action.payload.hearingId]: {
          invalid: {
            $set: {
              ...(state.hearings[action.payload.hearingId].invalid || {}),
              ...action.payload.invalid
            }
          }
        }
      }
    });
  case ACTIONS.SELECTED_HEARING_DAY_CHANGE:
    return update(state, {
      selectedHearingDay: {
        $set: action.payload.selectedHearingDay
      }
    });
  case ACTIONS.SCHEDULE_PERIOD_ERROR:
    return update(state, {
      spErrorDetails: {
        $set: action.payload.error
      },
      schedulePeriodError: {
        $set: true
      }
    });
  case ACTIONS.REMOVE_SCHEDULE_PERIOD_ERROR:
    return update(state, {
      $unset: ['schedulePeriodError']
    });
  case ACTIONS.SET_VACOLS_UPLOAD:
    return update(state, {
      vacolsUpload: {
        $set: true
      }
    });
  case ACTIONS.UPDATE_UPLOAD_FORM_ERRORS:
    return update(state, {
      uploadFormErrors: {
        $set: action.payload.errors
      }
    });
  case ACTIONS.UPDATE_RO_CO_UPLOAD_FORM_ERRORS:
    return update(state, {
      uploadRoCoFormErrors: {
        $set: action.payload.errors
      }
    });
  case ACTIONS.UPDATE_JUDGE_UPLOAD_FORM_ERRORS:
    return update(state, {
      uploadJudgeFormErrors: {
        $set: action.payload.errors
      }
    });
  case ACTIONS.UNSET_UPLOAD_ERRORS:
    return update(state, {
      $unset: [
        'uploadRoCoFormErrors',
        'uploadJudgeFormErrors'
      ]
    });
  case ACTIONS.FILE_TYPE_CHANGE:
    return update(state, {
      fileType: {
        $set: action.payload.fileType
      },
      $unset: ['uploadFormErrors']
    });
  case ACTIONS.RO_CO_START_DATE_CHANGE:
    return update(state, {
      roCoStartDate: {
        $set: action.payload.startDate
      }
    });
  case ACTIONS.RO_CO_END_DATE_CHANGE:
    return update(state, {
      roCoEndDate: {
        $set: action.payload.endDate
      }
    });
  case ACTIONS.RO_CO_FILE_UPLOAD:
    return update(state, {
      roCoFileUpload: {
        $set: action.payload.file
      }
    });
  case ACTIONS.JUDGE_START_DATE_CHANGE:
    return update(state, {
      judgeStartDate: {
        $set: action.payload.startDate
      }
    });
  case ACTIONS.JUDGE_END_DATE_CHANGE:
    return update(state, {
      judgeEndDate: {
        $set: action.payload.endDate
      }
    });
  case ACTIONS.VIEW_START_DATE_CHANGE:
    return update(state, {
      viewStartDate: {
        $set: action.payload.viewStartDate
      }
    });
  case ACTIONS.VIEW_END_DATE_CHANGE:
    return update(state, {
      viewEndDate: {
        $set: action.payload.viewEndDate
      }
    });
  case ACTIONS.JUDGE_FILE_UPLOAD:
    return update(state, {
      judgeFileUpload: {
        $set: action.payload.file
      }
    });
  case ACTIONS.TOGGLE_UPLOAD_CONTINUE_LOADING:
    return update(state, {
      $toggle: ['uploadContinueLoading']
    });
  case ACTIONS.CLICK_CONFIRM_ASSIGNMENTS:
    return update(state, {
      displayConfirmationModal: {
        $set: true
      }
    });
  case ACTIONS.CLICK_CLOSE_MODAL:
    return update(state, {
      displayConfirmationModal: {
        $set: false
      }
    });
  case ACTIONS.CONFIRM_ASSIGNMENTS_UPLOAD:
    return update(state, {
      displaySuccessMessage: {
        $set: true
      },
      $unset: [
        'fileType',
        'roCoStartDate',
        'roCoEndDate',
        'roCoFileUpload',
        'judgeStartDate',
        'judgeEndDate',
        'judgeFileUpload',
        'vacolsUpload'
      ]
    });
  case ACTIONS.UNSET_SUCCESS_MESSAGE:
    return update(state, {
      $unset: [
        'displaySuccessMessage',
        'schedulePeriod',
        'vacolsUpload'
      ]
    });
  case ACTIONS.TOGGLE_TYPE_FILTER_DROPDOWN:
    return update(state, {
      $toggle: ['filterTypeIsOpen']
    });
  case ACTIONS.TOGGLE_LOCATION_FILTER_DROPDOWN:
    return update(state, {
      $toggle: ['filterLocationIsOpen']
    });
  case ACTIONS.TOGGLE_VLJ_FILTER_DROPDOWN:
    return update(state, {
      $toggle: ['filterVljIsOpen']
    });
  case ACTIONS.SELECT_REQUEST_TYPE:
    return update(state, {
      requestType: {
        $set: action.payload.requestType
      }
    });
  case ACTIONS.SELECT_VLJ:
    return update(state, {
      vlj: {
        $set: action.payload.vlj
      }
    });
  case ACTIONS.SELECT_COORDINATOR:
    return update(state, {
      coordinator: {
        $set: action.payload.coordinator
      }
    });
  case ACTIONS.SELECT_HEARING_ROOM:
    return update(state, {
      hearingRoom: {
        $set: action.payload.hearingRoom
      }
    });
  case ACTIONS.SET_NOTES:
    return update(state, {
      notes: {
        $set: action.payload.notes
      }
    });
  case ACTIONS.ASSIGN_HEARING_ROOM:
    return update(state, {
      roomRequired: {
        $set: action.payload.roomRequired
      }
    });
  case ACTIONS.HEARING_DAY_MODIFIED:
    return update(state, {
      hearingDayModified: {
        $set: action.payload.hearingDayModified
      }
    });
  case ACTIONS.ON_CLICK_REMOVE_HEARING_DAY:
    return update(state, {
      displayRemoveHearingDayModal: {
        $set: true
      }
    });
  case ACTIONS.CANCEL_REMOVE_HEARING_DAY:
    return update(state, {
      $unset: ['displayRemoveHearingDayModal']
    });
  case ACTIONS.SUCCESSFUL_HEARING_DAY_DELETE:
    return update(state, {
      successfulHearingDayDelete: {
        $set: action.payload.date
      }
    });
  case ACTIONS.HANDLE_DAILY_DOCKET_SERVER_ERROR:
    return update(state, {
      dailyDocketServerError: { $set: true },
      displayRemoveHearingDayModal: { $set: false }
    });

  case ACTIONS.RESET_DAILY_DOCKET_AFTER_SERVER_ERROR:
    return update(state, {
      $unset: ['dailyDocketServerError']
    });

  case ACTIONS.HANDLE_LOCK_HEARING_SERVER_ERROR:
    return update(state, {
      onErrorHearingDayLock: { $set: true },
      displayLockModal: { $set: false }
    });

  case ACTIONS.RESET_LOCK_HEARING_SERVER_ERROR:
    return update(state, {
      $unset: ['onErrorHearingDayLock']
    });

  case ACTIONS.RESET_DELETE_SUCCESSFUL:
    return update(state, {
      $unset: ['successfulHearingDayDelete']
    });
  case ACTIONS.DISPLAY_LOCK_MODAL:
    return update(state, {
      displayLockModal: {
        $set: true
      }
    });
  case ACTIONS.CANCEL_DISPLAY_LOCK_MODAL:
    return update(state, {
      $unset: ['displayLockModal']
    });
  case ACTIONS.UPDATE_LOCK:
    return update(state, {
      dailyDocket: {
        lock: {
          $set: action.payload.lock
        }
      },
      displayLockSuccessMessage: {
        $set: true
      },
      $unset: ['displayLockModal']
    });
  case ACTIONS.RESET_LOCK_SUCCESS_MESSAGE:
    return update(state, {
      $unset: ['displayLockSuccessMessage']
    });
  default:
    return state;
  }
};
const combinedReducer = combineReducers({
  hearingSchedule: hearingScheduleReducer,
  ui: uiReducer,
  caseList: caseListReducer,
  queue: workQueueReducer,
  components: commonComponentsReducer
});

export default timeFunction(
  combinedReducer,
  (timeLabel, state, action) => `Action ${action.type} reducer time: ${timeLabel}`
);
