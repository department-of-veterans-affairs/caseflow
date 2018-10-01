import { ACTIONS, REQUEST_STATE } from '../constants';
import { FORM_TYPES } from '../../intakeCommon/constants';
import { update } from '../../util/ReducerUtil';
import { formatDateStr } from '../../util/DateUtil';
import { getOptionSelectedError, getPageError, getReceiptDateError, getAppealDocketError } from '../util/index';
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
    appealDocket: {
      $set: serverIntake.appeal_docket
    },
    electionReceiptDate: {
      $set: serverIntake.election_receipt_date && formatDateStr(serverIntake.election_receipt_date)
    },
    isReviewed: {
      $set: Boolean(serverIntake.option_selected && serverIntake.receipt_date)
    },
    issues: {
      $set: state.issues || _.keyBy(serverIntake.issues, 'id')
    },
    isComplete: {
      $set: Boolean(serverIntake.completed_at)
    },
    endProductDescription: {
      $set: serverIntake.end_product_description
    }
  });

  return result;
};

export const mapDataToInitialRampRefiling = (data = { serverIntake: {} }) => (
  updateFromServerIntake({
    optionSelected: null,
    optionSelectedError: null,
    appealDocket: null,
    appealDocketError: null,
    hasInvalidOption: false,
    receiptDate: null,
    receiptDateError: null,
    hasIneligibleIssue: false,
    isStarted: false,
    isReviewed: false,
    isComplete: false,
    outsideCaseflowStepsConfirmed: false,
    outsideCaseflowStepsError: null,
    endProductDescription: null,
    submitInvalidOptionError: false,
    reviewIntakeError: null,
    completeIntakeErrorCode: null,
    completeIntakeErrorData: null,

    // This allows us to tap into error events on the finish page and
    // scroll to the right element
    finishErrorProcessed: true,

    requestStatus: {
      submitReview: REQUEST_STATE.NOT_STARTED,
      completeIntake: REQUEST_STATE.NOT_STARTED
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
  case ACTIONS.SET_APPEAL_DOCKET:
    return update(state, {
      appealDocket: {
        $set: action.payload.appealDocket
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
      appealDocketError: {
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
      outsideCaseflowStepsError: {
        $set: null
      },
      issuesSelectedError: {
        $set: null
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
      appealDocketError: {
        $set: getAppealDocketError(action.payload.responseErrorCodes)
      },
      requestStatus: {
        submitReview: {
          $set: REQUEST_STATE.FAILED
        },
        reviewIntakeError: {
          $set: getPageError(action.payload.responseErrorCodes)
        }
      }
    });
  case ACTIONS.SET_HAS_INELIGIBLE_ISSUE:
    return update(state, {
      hasIneligibleIssue: {
        $set: action.payload.hasIneligibleIssue
      },
      issuesSelectedError: {
        $set: null
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
      },
      issuesSelectedError: {
        $set: null
      }
    });
  case ACTIONS.CONFIRM_OUTSIDE_CASEFLOW_STEPS:
    return update(state, {
      outsideCaseflowStepsConfirmed: {
        $set: action.payload.isConfirmed
      },
      outsideCaseflowStepsError: {
        $set: null
      },
      issuesSelectedError: {
        $set: null
      }
    });
  case ACTIONS.COMPLETE_INTAKE_STEPS_NOT_CONFIRMED:
    return update(state, {
      outsideCaseflowStepsError: {
        $set: "You must confirm you've completed the steps"
      },
      finishErrorProcessed: {
        $set: false
      }
    });
  case ACTIONS.PROCESS_FINISH_ERROR:
    return update(state, {
      finishErrorProcessed: {
        $set: true
      }
    });
  case ACTIONS.NO_ISSUES_SELECTED_ERROR:
    return update(state, {
      issuesSelectedError: {
        $set: 'You must select at least one contention'
      }
    });
  case ACTIONS.COMPLETE_INTAKE_START:
    return update(state, {
      requestStatus: {
        completeIntake: {
          $set: REQUEST_STATE.IN_PROGRESS
        }
      }
    });
  case ACTIONS.COMPLETE_INTAKE_FAIL:
    return update(state, {
      requestStatus: {
        completeIntake: {
          $set: REQUEST_STATE.FAILED
        },
        completeIntakeErrorCode: {
          $set: action.payload.responseErrorCode
        },
        completeIntakeErrorData: {
          $set: action.payload.responseErrorData
        }
      }
    });
  case ACTIONS.COMPLETE_INTAKE_SUCCEED:
    return updateFromServerIntake(update(state, {
      isComplete: {
        $set: true
      },
      requestStatus: {
        completeIntake: {
          $set: REQUEST_STATE.SUCCEEDED
        }
      }
    }), action.payload.intake);
  case ACTIONS.CONFIRM_INELIGIBLE_FORM:
    return update(state, {
      requestStatus: {
        submitReview: {
          $set: REQUEST_STATE.FAILED
        }
      }
    });
  case ACTIONS.SUBMIT_ERROR_FAIL:
    return update(state, {
      submitInvalidOptionError: {
        $set: true
      }
    });
  default:
    return state;
  }
};
