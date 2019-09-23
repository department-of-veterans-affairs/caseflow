import React from 'react';
import PropTypes from 'prop-types';

import { connect } from 'react-redux';
import TextareaField from '../../components/TextareaField';
import Modal from '../../components/Modal';
import * as Constants from '../constants';
import { getCancelFeedbackErrorMessage } from '../selectors';
import ApiUtil from '../../util/ApiUtil';
import WindowUtil from '../../util/WindowUtil';

const CANCEL_ERRORS = {
  task_already_completed: {
    header: 'This task was already completed.',
    body: <span>
            Please return
            to <a href="/dispatch/establish-claim/">Work History</a> to
            establish the next claim.
    </span>
  },
  default: {
    header: 'Error',
    body: 'There was an error while cancelling the current claim. ' +
          'Please try again later'
  }
};

export const CancelModal = ({
  cancelFeedback,
  errorMessage,
  isSubmittingCancelFeedback,
  isShowingCancelModal,
  handleChangeCancelFeedback,
  handleCancelSubmit,
  handleCloseCancelModal
}) => {
  return <div>
    {isShowingCancelModal && <Modal
      buttons={[
        { classNames: ['cf-modal-link', 'cf-btn-link'],
          name: 'Close',
          onClick: handleCloseCancelModal
        },
        { classNames: ['usa-button', 'usa-button-secondary'],
          loading: isSubmittingCancelFeedback,
          name: 'Stop processing claim',
          onClick: handleCancelSubmit
        }
      ]}
      visible
      closeHandler={handleCloseCancelModal}
      title="Stop Processing Claim">
      <p>
        If you click the <b>Stop processing claim </b>
        button below your work will not be
        saved and an EP will not be created for this claim.
      </p>
      <p>
        Please tell us why you have chosen to discontinue processing this claim.
      </p>
      <TextareaField
        label="Explanation"
        name="Explanation"
        onChange={handleChangeCancelFeedback}
        required
        errorMessage={errorMessage}
        value={cancelFeedback}
      />
    </Modal>}
  </div>;
};

CancelModal.propTypes = {
  cancelFeedback: PropTypes.string.isRequired,
  errorMessage: PropTypes.string,
  isSubmittingCancelFeedback: PropTypes.bool.isRequired,
  isShowingCancelModal: PropTypes.bool.isRequired,
  handleChangeCancelFeedback: PropTypes.func.isRequired,
  handleCancelSubmit: PropTypes.func.isRequired,
  handleCloseCancelModal: PropTypes.func.isRequired,
  handleAlert: PropTypes.func,
  handleAlertClear: PropTypes.func
};

const mapStateToProps = (state) => {
  return {
    isShowingCancelModal: state.establishClaim.isShowingCancelModal,
    isSubmittingCancelFeedback: state.establishClaim.isSubmittingCancelFeedback,
    cancelFeedback: state.establishClaim.cancelFeedback,
    errorMessage: getCancelFeedbackErrorMessage(state.establishClaim)
  };
};

const mapDispatchToProps = (dispatch, ownProps) => ({
  handleCloseCancelModal: () => {
    dispatch({
      type: Constants.TOGGLE_CANCEL_TASK_MODAL
    });
  },
  handleCancelSubmit: () => (
    dispatch((_dispatch, getState) => {
      _dispatch({ type: Constants.VALIDATE_CANCEL_FEEDBACK });
      const isInvalid =
        Boolean(getCancelFeedbackErrorMessage(getState().establishClaim));

      if (isInvalid) {
        return;
      }

      _dispatch({ type: Constants.REQUEST_CANCEL_FEEDBACK });
      ownProps.handleAlertClear();

      const data = ApiUtil.convertToSnakeCase({
        feedback: getState().establishClaim.cancelFeedback
      });

      ApiUtil.patch(`/dispatch/establish-claim/${ownProps.taskId}/cancel`, { data }).
        then(() => {
          WindowUtil.reloadPage();
        }, (error) => {
          _dispatch({ type: Constants.REQUEST_CANCEL_FEEDBACK_FAILURE });

          let errorMessage = CANCEL_ERRORS[error.response.body.error_code] ||
                             CANCEL_ERRORS.default;

          ownProps.handleAlert(
            'error',
            errorMessage.header,
            errorMessage.body
          );
        });
    })
  ),
  handleChangeCancelFeedback: (value) => {
    dispatch({
      type: Constants.CHANGE_CANCEL_FEEDBACK,
      payload: {
        value
      }
    });
  }
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(CancelModal);
