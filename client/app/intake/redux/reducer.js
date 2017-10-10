import { ACTIONS, REQUEST_STATE } from '../constants';
import { update } from '../../util/ReducerUtil';

const initialState = {
  veteran: {
    name: null,
    fileNumber: null
  },
  inputs: {
    fileNumberSearch: '',
    receiptDateStr: '',
    veteranResponse: null
  },
  requestStatus: {
    fileNumberSearch: REQUEST_STATE.NOT_STARTED
  },
  searchError: null
};

export default (state = initialState, action) => {
  switch (action.type) {
  case ACTIONS.START_NEW_INTAKE:
    return initialState;
  case ACTIONS.SET_FILE_NUMBER_SEARCH:
    return update(state, {
      inputs: {
        fileNumberSearch: {
          $set: action.payload.fileNumber
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
        fileNumber: {
          $set: action.payload.fileNumber
        }
      }
    });
  case ACTIONS.FILE_NUMBER_SEARCH_FAIL:
    const searchErrors = {
      invalid_file_number: {
        title: 'Veteran ID not found',
        body: 'Please enter a valid Veteran ID and try again.'
      },
      // TODO: Add the other error messages her
      didnt_receive_ramp_election: {
        title: 'No opt-in letter was sent to this veteran',
        body: "An opt-in letter was not sent to this Veteran, so this form can't be processed" +
          'Please enter a valid Veteran ID below.'
      },
      default: {
        title: 'Something went wrong',
        body: 'Please try again. If the problem persists, please contact Caseflow support.'
      }
    };

    return update(state, {
      searchError: {
        $set: (searchErrors[action.payload.errorCode] || searchErrors.default)
      },
      requestStatus: {
        fileNumberSearch: {
          $set: REQUEST_STATE.FAILED
        }
      }
    });
  default:
    return state;
  }
};
