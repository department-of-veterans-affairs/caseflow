import { ACTIONS, REQUEST_STATE, FORM_TYPES } from '../constants';
import { update } from '../../util/ReducerUtil';
import { formatDateStr } from '../../util/DateUtil';
import { getReceiptDateError, formatRatings } from '../util';
import _ from 'lodash';

const getInformalConferenceError = (responseErrorCodes) => (
  (_.get(responseErrorCodes.informal_conference, 0) === 'blank') && 'Please select an option.'
);

const getSameOfficeError = (responseErrorCodes) => (
  (_.get(responseErrorCodes.same_office, 0) === 'blank') && 'Please select an option.'
);

const updateFromServerIntake = (state, serverIntake) => {
  if (serverIntake.form_type !== FORM_TYPES.HIGHER_LEVEL_REVIEW.key) {
    return state;
  }

  return update(state, {
    isStarted: {
      $set: Boolean(serverIntake.id)
    },
    informalConference: {
      $set: serverIntake.informal_conference
    },
    sameOffice: {
      $set: serverIntake.same_office
    },
    receiptDate: {
      $set: serverIntake.receipt_date && formatDateStr(serverIntake.receipt_date)
    },
    isReviewed: {
      $set: Boolean(serverIntake.receipt_date)
    },
    ratings: {
      $set: state.ratings || formatRatings(serverIntake.ratings)
    },
    isComplete: {
      $set: Boolean(serverIntake.completed_at)
    }
  });
};

export const mapDataToInitialHigherLevelReview = (data = { serverIntake: {} }) => (
  updateFromServerIntake({
    receiptDate: null,
    receiptDateError: null,
    informalConference: null,
    informalConferenceError: null,
    sameOffice: null,
    sameOfficeError: null,
    isStarted: false,
    isReviewed: false,
    isComplete: false,
    requestStatus: {
      submitReview: REQUEST_STATE.NOT_STARTED
    }
  }, data.serverIntake)
);

export const higherLevelReviewReducer = (state = mapDataToInitialHigherLevelReview(), action) => {
  switch (action.type) {
  case ACTIONS.START_NEW_INTAKE:
    return mapDataToInitialHigherLevelReview();
  case ACTIONS.FILE_NUMBER_SEARCH_SUCCEED:
    return updateFromServerIntake(state, action.payload.intake);
  default:
  }

  // The rest of the actions only should be processed if a HigherLevelReview intake is being processed
  if (!state.isStarted) {
    return state;
  }

  switch (action.type) {
  case ACTIONS.CANCEL_INTAKE_SUCCEED:
    return mapDataToInitialHigherLevelReview();
  case ACTIONS.SET_INFORMAL_CONFERENCE:
    return update(state, {
      informalConference: {
        $set: action.payload.informalConference
      }
    });
  case ACTIONS.SET_SAME_OFFICE:
    return update(state, {
      sameOffice: {
        $set: action.payload.sameOffice
      }
    });
  case ACTIONS.SET_RECEIPT_DATE:
    return update(state, {
      receiptDate: {
        $set: action.payload.receiptDate
      }
    });
  case ACTIONS.SUBMIT_REVIEW_START:
    return update(state, {
      requestStatus: {
        submitReview: {
          $set: REQUEST_STATE.IN_PROGRESS
        }
      }
    });
  case ACTIONS.SUBMIT_REVIEW_SUCCEED:
    return update(state, {
      informalConferenceError: {
        $set: null
      },
      sameOfficeError: {
        $set: null
      },
      receiptDateError: {
        $set: null
      },
      isReviewed: {
        $set: true
      },
      requestStatus: {
        submitReview: {
          $set: REQUEST_STATE.SUCCEEDED
        }
      }
    });
  case ACTIONS.SUBMIT_REVIEW_FAIL:
    return update(state, {
      informalConferenceError: {
        $set: getInformalConferenceError(action.payload.responseErrorCodes)
      },
      sameOfficeError: {
        $set: getSameOfficeError(action.payload.responseErrorCodes)
      },
      receiptDateError: {
        $set: getReceiptDateError(action.payload.responseErrorCodes, state)
      },
      requestStatus: {
        submitReview: {
          $set: REQUEST_STATE.FAILED
        }
      }
    });
  case ACTIONS.SET_ISSUE_SELECTED:
    return update(state, {
      ratings: {
        [action.payload.profileDate]: {
          issues: {
            [action.payload.issueId]: {
              isSelected: {
                $set: action.payload.isSelected
              }
            }
          }
        }
      }
    });
  default:
    return state;
  }
};
