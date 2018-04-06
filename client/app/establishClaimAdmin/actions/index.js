import * as Constants from '../constants';
import ApiUtil from '../../util/ApiUtil';

export const populateStuckTasks = ({ tasks }) => ({
  type: Constants.POPULATE_STUCK_TASKS,
  payload: {
    tasks
  }
});

export const fetchStuckTasks = () => (dispatch) => {
  dispatch({ type: Constants.SET_LOADING_STATE,
    payload: { value: true } });
  ApiUtil.get('/manage/claims').
    then((response) => {
      dispatch(populateStuckTasks(response.body));
    });
};
