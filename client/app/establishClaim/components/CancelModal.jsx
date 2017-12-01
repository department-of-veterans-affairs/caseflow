import React from 'react';
import PropTypes from 'prop-types';

import { connect } from 'react-redux';
import TextareaField from '../../components/TextareaField';
import Modal from '../../components/Modal';
import * as Constants from '../constants';
import { getCancelFeedbackErrorMessage } from '../selectors';
import ApiUtil from '../../util/ApiUtil';
import WindowUtil from '../../util/WindowUtil';

export const CancelModal = ({
  cancelFeedback,
  errorMessage,
  isCancelModalSubmitting,
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
          loading: isCancelModalSubmitting,
          name: 'Stop processing claim',
          onClick: handleCancelSubmit
        }
      ]}
      visible={true}
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
        required={true}
        errorMessage={errorMessage}
        value={cancelFeedback}
      />
    </Modal>}
  </div>;
};

CancelModal.PropTypes = {
  cancelFeedback: PropTypes.string.isRequired,
  errorMessage: PropTypes.string,
  isCancelModalSubmitting: PropTypes.bool.isRequired,
  isShowingCancelModal: PropTypes.bool.isRequired,
  handleChangeCancelFeedback: PropTypes.func.isRequired,
  handleCancelSubmit: PropTypes.func.isRequired,
  handleCloseCancelModal: PropTypes.func.isRequired
};

const mapStateToProps = (state) => {
  return {
    isShowingCancelModal: state.establishClaim.isShowingCancelModal,
    isCancelModalSubmitting: state.establishClaim.isCancelModalSubmitting,
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
        }, () => {
          _dispatch({ type: Constants.REQUEST_CANCEL_FEEDBACK_FAILURE });
          ownProps.handleAlert(
            'error',
            'Error',
            'There was an error while cancelling the current claim.' +
            ' Please try again later'
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
