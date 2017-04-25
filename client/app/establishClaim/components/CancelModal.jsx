import React, { PropTypes } from 'react';
import { connect } from 'react-redux';
import TextareaField from '../../components/TextareaField';
import Modal from '../../components/Modal';
import * as Constants from '../constants';

export const CancelModal = ({
  cancelFeedback,
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
      closeHandler={isCancelModalSubmitting}
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
        value={cancelFeedback}
      />
    </Modal>}
  </div>;
};

const mapStateToProps = (state) => {
  return {
    isShowingCancelModal: state.establishClaim.isShowingCancelModal,
    isCancelModalSubmitting: state.establishClaim.isCancelModalSubmitting,
    cancelFeedback: state.establishClaim.cancelFeedback
  };
};

const mapDispatchToProps = (dispatch) => {
  return {
    handleCloseCancelModal: () => {
      dispatch({
        type: Constants.CLOSE_CANCEL_MODAL
      });
    },
    handleCancelSubmit: () => {
    },
    handleChangeCancelFeedback: (value) => {
      dispatch({
        type: Constants.CHANGE_CANCEL_FEEDBACK,
        payload: {
          value
        }
      });
    }
  };
};

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(CancelModal);
