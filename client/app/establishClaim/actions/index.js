import * as Constants from '../constants';

export const handleToggleCancelTaskModal = () => (dispatch) => {
  dispatch({ type: Constants.TOGGLE_CANCEL_TASK_MODAL });
}
