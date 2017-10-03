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
  }
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
  default:
    return state;
  }
};
