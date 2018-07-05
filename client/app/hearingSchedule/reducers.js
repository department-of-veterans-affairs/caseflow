import {ACTIONS} from './constants';
import {update} from '../util/ReducerUtil';

export const initialState = {};

const reducers = (state = initialState, action = {}) => {
  switch (action.type) {
    case ACTIONS.RECEIVE_PAST_UPLOADS:
      return update(state, {
        pastUploads: {
          $set: action.payload.pastUploads
        }
      });
    case ACTIONS.FILE_TYPE_CHANGE:
      return update(state, {
        fileType: {
          $set: action.payload.fileType
        }
      });
    case ACTIONS.RECEIVE_HEARING_SCHEDULE:
      return update(state, {
        hearingSchedule: {
          $set: action.payload.hearingSchedule
        }
      })
    default:
      return state;
  }
};

export default reducers;
