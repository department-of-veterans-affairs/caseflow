import { ACTIONS, REQUEST_STATE } from '../constants';
import { update } from '../../util/ReducerUtil';
import { formatDateStr } from '../../util/DateUtil';
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
  return update(state, {
    isStarted: {
      $set: Boolean(serverIntake.id)
    },
    noticeDate: {
      $set: serverIntake.notice_date && formatDateStr(serverIntake.notice_date)
    },
    optionSelected: {
      $set: serverIntake.option_selected
    },
    receiptDate: {
      $set: serverIntake.receipt_date && formatDateStr(serverIntake.receipt_date)
    },
    isReviewed: {
      $set: Boolean(serverIntake.option_selected && serverIntake.receipt_date)
    },
    isComplete: {
      $set: Boolean(serverIntake.completed_at)
    },
    endProductDescription: {
      $set: serverIntake.end_product_description
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
    requestStatus: {
      submitReview: REQUEST_STATE.NOT_STARTED,
      completeIntake: REQUEST_STATE.NOT_STARTED
    }
  }, data.serverIntake)
);

const getOptionSelectedError = (responseErrorCodes) => (
  _.get(responseErrorCodes.option_selected, 0) && 'Please select an option.'
);

const getReceiptDateError = (responseErrorCodes, state) => (
  {
    blank:
      'Please enter a valid receipt date.',
    in_future:
      'Receipt date cannot be in the future.',
    before_notice_date: 'Receipt date cannot be earlier than the election notice ' +
      `date of ${state.noticeDate}`
  }[_.get(responseErrorCodes.receipt_date, 0)]
);

export const rampElectionReducer = (state = mapDataToInitialRampElection(), action) => {
  switch (action.type) {
  case ACTIONS.START_NEW_INTAKE:
    return mapDataToInitialRampElection();
  case ACTIONS.FILE_NUMBER_SEARCH_SUCCEED:
    return updateFromServerIntake(state, action.payload.intake);
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
        }
      }
    });
  default:
    return state;
  }
};
