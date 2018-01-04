import { ACTIONS, REQUEST_STATE, FORM_TYPES } from '../constants';
import { update } from '../../util/ReducerUtil';
import { formatDateStr } from '../../util/DateUtil';
import { getOptionSelectedError, getReceiptDateError } from '../util/index';
import _ from 'lodash';

const updateFromServerIntake = (state, serverIntake) => {
  if (serverIntake.form_type !== FORM_TYPES.RAMP_REFILING.key) {
    return state;
  }

  const result = update(state, {
    isStarted: {
      $set: Boolean(serverIntake.id)
    },
    optionSelected: {
      $set: serverIntake.option_selected
    },
    receiptDate: {
      $set: serverIntake.receipt_date && formatDateStr(serverIntake.receipt_date)
    },
    electionReceiptDate: {
      $set: serverIntake.election_receipt_date && formatDateStr(serverIntake.election_receipt_date)
    },
    isReviewed: {
      $set: Boolean(serverIntake.option_selected && serverIntake.receipt_date)
    },
    issues: {
      $set: _.keyBy(serverIntake.issues, 'id')
    }
  });

  return result;
};

export const mapDataToInitialRampRefiling = (data = { serverIntake: {} }) => (
  updateFromServerIntake({
    optionSelected: null,
    optionSelectedError: null,
    hasInvalidOption: false,
    receiptDate: null,
    receiptDateError: null,
    hasIneligibleIssue: false,
    isStarted: false,
    isReviewed: false,
    outsideCaseflowStepsConfirmed: false,
    requestStatus: {
      submitReview: REQUEST_STATE.NOT_STARTED
    }
  }, data.serverIntake)
);

const getHasInvalidOption = (responseErrorCodes) => (
  _.get(responseErrorCodes.option_selected, 0) === 'higher_level_review_invalid'
);

export const rampRefilingReducer = (state = mapDataToInitialRampRefiling(), action) => {
  switch (action.type) {
  case ACTIONS.START_NEW_INTAKE:
    return mapDataToInitialRampRefiling();
  case ACTIONS.FILE_NUMBER_SEARCH_SUCCEED:
    return updateFromServerIntake(state, action.payload.intake);
  default:
  }

  // The rest of the actions only should be processed if a RampRefiling intake is being processed
  if (!state.isStarted) {
    return state;
  }

  switch (action.type) {
  case ACTIONS.CANCEL_INTAKE_SUCCEED:
    return mapDataToInitialRampRefiling();
  case ACTIONS.SET_OPTION_SELECTED:
    return update(state, {
      optionSelected: {
        $set: action.payload.optionSelected
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
      optionSelectedError: {
        $set: null
      },
      receiptDateError: {
        $set: null
      },
      hasInvalidOption: {
        $set: null
      },
      isReviewed: {
        $set: true
      },
      outsideCaseflowStepsConfirmed: {
        $set: false
      },
      requestStatus: {
        submitReview: {
          $set: REQUEST_STATE.SUCCEEDED
        }
      }
    });
  case ACTIONS.SUBMIT_REVIEW_FAIL:
    return update(state, {
      hasInvalidOption: {
        $set: getHasInvalidOption(action.payload.responseErrorCodes)
      },
      optionSelectedError: {
        $set: getOptionSelectedError(action.payload.responseErrorCodes)
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
  case ACTIONS.SET_HAS_INELIGIBLE_ISSUE:
    return update(state, {
      hasIneligibleIssue: {
        $set: action.payload.hasIneligibleIssue
      }
    });
  case ACTIONS.SET_ISSUE_SELECTED:
    return update(state, {
      issues: {
        [action.payload.issueId]: {
          isSelected: {
            $set: action.payload.isSelected
          }
        }
      }
    });
  case ACTIONS.CONFIRM_OUTSIDE_CASEFLOW_STEPS:
    return update(state, {
      outsideCaseflowStepsConfirmed: {
        $set: action.payload.isConfirmed
      }
    });
  default:
    return state;
  }
};
