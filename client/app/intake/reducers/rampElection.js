import { ACTIONS, FORM_TYPES, REQUEST_STATE } from '../constants';
import { update } from '../../util/ReducerUtil';
import { formatDateStr } from '../../util/DateUtil';
import { getBlankOptionError, getPageError, getReceiptDateError } from '../util';
import _ from 'lodash';

const formatAppeals = (appeals) => {
  return _.map(appeals, (appeal) => (
    {
      id: appeal.id,
      issues: appeal.issues.map(
        ({ program_description, ...rest }) => ({
          programDescription: program_description,
          ...rest
        })
      )
    }
  ));
};

const updateFromServerIntake = (state, serverIntake) => {
  if (serverIntake.form_type !== FORM_TYPES.RAMP_ELECTION.key) {
    return state;
  }

  return update(state, {
    isStarted: {
      $set: Boolean(serverIntake.id)
    },
    noticeDate: {
      $set: serverIntake.notice_date && formatDateStr(serverIntake.notice_date)
    },
    optionSelected: {
      $set: serverIntake.optionSelected
    },
    receiptDate: {
      $set: serverIntake.receiptDate
    },
    isReviewed: {
      $set: Boolean(serverIntake.optionSelected && serverIntake.receiptDate)
    },
    isComplete: {
      $set: Boolean(serverIntake.completed_at)
    },
    endProductDescription: {
      $set: serverIntake.endProductDescription
    },
    appeals: {
      $set: formatAppeals(serverIntake.appeals)
    }
  });
};

export const mapDataToInitialRampElection = (data = { serverIntake: {} }) => (
  updateFromServerIntake({
    noticeDate: null,
    optionSelected: null,
    optionSelectedError: null,
    receiptDate: null,
    receiptDateError: null,
    isStarted: false,
    isReviewed: false,
    isComplete: false,
    finishConfirmed: false,
    finishConfirmedError: null,
    reviewIntakeError: null,
    completeIntakeErrorCode: null,
    completeIntakeErrorData: null,
    requestStatus: {
      submitReview: REQUEST_STATE.NOT_STARTED,
      completeIntake: REQUEST_STATE.NOT_STARTED
    }
  }, data.serverIntake)
);

export const rampElectionReducer = (state = mapDataToInitialRampElection(), action) => {
  switch (action.type) {
  case ACTIONS.START_NEW_INTAKE:
    return mapDataToInitialRampElection();
  case ACTIONS.FILE_NUMBER_SEARCH_SUCCEED:
    return updateFromServerIntake(state, action.payload.intake);
  default:
  }

  // The rest of the actions only should be processed if a RampElection intake is being processed
  if (!state.isStarted) {
    return state;
  }

  switch (action.type) {
  case ACTIONS.CANCEL_INTAKE_SUCCEED:
    return mapDataToInitialRampElection();
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
  case ACTIONS.SET_RECEIPT_DATE_ERROR:
    return update(state, {
      receiptDateError: {
        $set: action.payload.receiptDateError
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
      finishConfirmed: {
        $set: null
      },
      finishConfirmedError: {
        $set: null
      },
      isReviewed: {
        $set: true
      },
      requestStatus: {
        submitReview: {
          $set: REQUEST_STATE.SUCCEEDED
        },
        completeIntake: {
          $set: REQUEST_STATE.NOT_STARTED
        }
      }
    });
  case ACTIONS.SUBMIT_REVIEW_FAIL:
    return update(state, {
      optionSelectedError: {
        $set: getBlankOptionError(action.payload.responseErrorCodes, 'option_selected')
      },
      receiptDateError: {
        $set: getReceiptDateError(action.payload.responseErrorCodes, state)
      },
      requestStatus: {
        submitReview: {
          $set: REQUEST_STATE.FAILED
        },
        reviewIntakeError: {
          $set: getPageError(action.payload)
        }
      }
    });
  case ACTIONS.CONFIRM_FINISH_INTAKE:
    return update(state, {
      finishConfirmed: {
        $set: action.payload.isConfirmed
      }
    });
  case ACTIONS.COMPLETE_INTAKE_NOT_CONFIRMED:
    return update(state, {
      finishConfirmedError: {
        $set: "You must confirm you've completed the steps"
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
  default:
    return state;
  }
};
