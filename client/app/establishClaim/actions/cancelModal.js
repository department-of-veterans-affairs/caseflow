import ApiUtil from '../../util/ApiUtil';
import WindowUtil from '../../util/WindowUtil';
import * as Constants from '../constants';
import { getCancelFeedbackErrorMessage } from '../selectors';

export const handleCancelSubmit = (_dispatch, ownProps) => () => (
  _dispatch((dispatch, getState) => {
    dispatch({ type: Constants.VALIDATE_CANCEL_FEEDBACK });
    const isInvalid =
      Boolean(getCancelFeedbackErrorMessage(getState().establishClaim));

    if (isInvalid) {
      return;
    }

    dispatch({ type: Constants.REQUEST_CANCEL_FEEDBACK });
    ownProps.handleAlertClear();

    const data = ApiUtil.convertToSnakeCase({
      feedback: getState().establishClaim.cancelFeedback
    });

    ApiUtil.patch(`/dispatch/establish-claim/${ownProps.taskId}/cancel`, { data }).
      then(() => {
        WindowUtil.reloadPage();
      }, () => {
        dispatch({ type: Constants.REQUEST_CANCEL_FEEDBACK_FAILURE });
        ownProps.handleAlert(
          'error',
          'Error',
          'There was an error while cancelling the current claim.' +
          ' Please try again later'
        );
      });
  })
);
