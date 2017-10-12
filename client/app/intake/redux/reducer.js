import { ACTIONS, REQUEST_STATE } from '../constants';
import { update } from '../../util/ReducerUtil';
import { formatDateStr } from '../../util/DateUtil';

export const mapDataToInitialState = (data = { currentIntake: {} }) => ({
  veteran: {
    name: data.currentIntake.veteran_name,
    formName: data.currentIntake.veteran_form_name,
    fileNumber: data.currentIntake.veteran_file_number
  },
  inputs: {
    fileNumberSearch: '',
    receiptDateStr: '',
    veteranResponse: null
  },
  requestStatus: {
    fileNumberSearch: REQUEST_STATE.NOT_STARTED,
    submitReview: REQUEST_STATE.NOT_STARTED
  },
  rampElection: {
    intakeId: data.currentIntake.id,
    noticeDate: data.currentIntake.notice_date,
    optionSelected: null,
    optionSelectedError: null,
    receiptDate: null,
    receiptDateError: null
  },
  searchError: null
});

const getOptionSelectedError = (responseErrorCodes) => (
  (responseErrorCodes.option_selected || [])[0] && 'Please select an option.'
);

const getReceiptDateError = (responseErrorCodes, state) => (
  {
    blank:
      'Please enter a valid receipt date.',
    in_future:
      'Receipt date cannot be in the future.',
    before_notice_date: 'Receipt date cannot be earlier than the election notice ' +
      `date of ${formatDateStr(state.rampElection.noticeDate)}`
  }[(responseErrorCodes.receipt_date || [])[0]]
);

// The keys in this object need to be snake_case
// because they're being matched to server response values.
const searchErrors = {
  invalid_file_number: {
    title: 'Veteran ID not found',
    body: 'Please enter a valid Veteran ID and try again.'
  },
  veteran_not_found: {
    title: 'Veteran ID not found',
    body: 'Please enter a valid Veteran ID and try again.'
  },
  veteran_not_accessible: {
    title: 'You don\'t have permission to view this veteran\'s information​',
    body: 'Please enter a valid Veteran ID and try again.'
  },
  did_not_receive_ramp_election: {
    title: 'No opt-in letter was sent to this veteran',
    body: "An opt-in letter was not sent to this Veteran, so this form can't be processed. " +
      'Please enter a valid Veteran ID below.'
  },
  default: {
    title: 'Something went wrong',
    body: 'Please try again. If the problem persists, please contact Caseflow support.'
  }
};

export const reducer = (state = mapDataToInitialState(), action) => {
  switch (action.type) {
  case ACTIONS.START_NEW_INTAKE:
    return mapDataToInitialState();
  case ACTIONS.SET_FILE_NUMBER_SEARCH:
    return update(state, {
      inputs: {
        fileNumberSearch: {
          $set: action.payload.fileNumber
        }
      }
    });
  case ACTIONS.SET_OPTION_SELECTED:
    return update(state, {
      rampElection: {
        optionSelected: {
          $set: action.payload.optionSelected
        }
      }
    });
  case ACTIONS.SET_RECEIPT_DATE:
    return update(state, {
      rampElection: {
        receiptDate: {
          $set: action.payload.receiptDate
        }
      }
    });
  case ACTIONS.FILE_NUMBER_SEARCH_START:
    return update(state, {
      requestStatus: {
        fileNumberSearch: {
          $set: REQUEST_STATE.IN_PROGRESS
        }
      }
    });
  case ACTIONS.FILE_NUMBER_SEARCH_SUCCEED:
    return update(state, {
      requestStatus: {
        fileNumberSearch: {
          $set: REQUEST_STATE.SUCCEEDED
        }
      },
      veteran: {
        name: {
          $set: action.payload.name
        },
        formName: {
          $set: action.payload.formName
        },
        fileNumber: {
          $set: action.payload.fileNumber
        }
      },
      rampElection: {
        intakeId: {
          $set: action.payload.intakeId
        },
        noticeDate: {
          $set: action.payload.noticeDate
        }
      }
    });
  case ACTIONS.FILE_NUMBER_SEARCH_FAIL:
    return update(state, {
      searchError: {
        $set: searchErrors[action.payload.errorCode] || searchErrors.default
      },
      requestStatus: {
        fileNumberSearch: {
          $set: REQUEST_STATE.FAILED
        }
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
      requestStatus: {
        submitReview: {
          $set: REQUEST_STATE.SUCCEEDED
        }
      }
    });
  case ACTIONS.SUBMIT_REVIEW_FAIL:
    return update(state, {
      rampElection: {
        optionSelectedError: {
          $set: getOptionSelectedError(action.payload.responseErrorCodes)
        },
        receiptDateError: {
          $set: getReceiptDateError(action.payload.responseErrorCodes, state)
        }
      },
      requestStatus: {
        submitReview: {
          $set: REQUEST_STATE.FAILED
        }
      }
    });
  default:
    return state;
  }
};
