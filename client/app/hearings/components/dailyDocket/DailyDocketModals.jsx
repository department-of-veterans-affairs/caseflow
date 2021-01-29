import React from 'react';
import PropTypes from 'prop-types';
import moment from 'moment';
import { sprintf } from 'sprintf-js';

import COPY from '../../../../COPY';
import Modal from '../../../components/Modal';
import Button from '../../../components/Button';
import { dispositionLabel } from '../../utils';

export const RemoveHearingModal = ({ onCancelRemoveHearingDay, deleteHearingDay, dailyDocket }) => (
  <div>
    <Modal
      title={COPY.REMOVE_HEARING_DAY_MESSAGE_TITLE}
      closeHandler={onCancelRemoveHearingDay}
      confirmButton={
        <Button classNames={['usa-button-secondary']} onClick={deleteHearingDay}>
          Confirm
        </Button>
      }
      cancelButton={
        <Button linkStyling onClick={onCancelRemoveHearingDay}>
          Go back
        </Button>
      }
    >
      {sprintf(
        COPY.REMOVE_HEARING_DAY_MESSAGE_DETAIL,
        dailyDocket.readableRequestType,
        moment(dailyDocket.scheduledFor).format('ddd M/DD/YYYY')
      )}
    </Modal>
  </div>
);

RemoveHearingModal.propTypes = {
  onCancelRemoveHearingDay: PropTypes.func.isRequired,
  deleteHearingDay: PropTypes.func,
  dailyDocket: PropTypes.object
};

export const LockModal = ({ updateLockHearingDay, onCancelDisplayLockModal, dailyDocket }) => (
  <div>
    <Modal
      title={dailyDocket.lock ? COPY.UNLOCK_HEARING_DAY_MESSAGE_TITLE : COPY.LOCK_HEARING_DAY_MESSAGE_TITLE}
      closeHandler={onCancelDisplayLockModal}
      confirmButton={
        <Button classNames={['usa-button-secondary']} onClick={updateLockHearingDay(!dailyDocket.lock)}>
          Confirm
        </Button>
      }
      cancelButton={
        <Button linkStyling onClick={onCancelDisplayLockModal}>
          Go back
        </Button>
      }
    >
      {dailyDocket.lock && COPY.UNLOCK_HEARING_DAY_MESSAGE_DETAIL}
      {!dailyDocket.lock && COPY.LOCK_HEARING_DAY_MESSAGE_DETAIL}
    </Modal>
  </div>
);

LockModal.propTypes = {
  updateLockHearingDay: PropTypes.func,
  onCancelDisplayLockModal: PropTypes.func,
  dailyDocket: PropTypes.object
};

export const AodModal = ({ onConfirm, onCancel, advanceOnDocketMotion }) => (
  <div>
    <Modal
      title="There is a prior AOD decision"
      closeHandler={onCancel}
      cancelButton={
        <Button linkStyling onClick={onCancel}>
          Cancel
        </Button>
      }
      confirmButton={
        <Button classNames={['usa-button-secondary']} onClick={onConfirm}>
          Confirm
        </Button>
      }
    >
      This AOD was&nbsp;<strong>{advanceOnDocketMotion.granted ? 'granted' : 'denied'}</strong>&nbsp;on&nbsp;
      {moment(advanceOnDocketMotion.date).format('MM/DD/YYYY')}&nbsp;by Judge&nbsp;{advanceOnDocketMotion.judgeName}.
      &nbsp;Changing this AOD will override this previous decision.
    </Modal>
  </div>
);

AodModal.propTypes = {
  onConfirm: PropTypes.func,
  onCancel: PropTypes.func,
  advanceOnDocketMotion: PropTypes.object
};

export class DispositionModal extends React.Component {
  COPY = {
    CASEFLOW: {
      body: (
        <span>
          <p>
            You are changing the hearing disposition for this case. Changing the disposition will change where the case
            is sent next
          </p>
          <p>
            The Daily Docket will be locked the day after the hearing date and will require administrative access to
            change after that time.
          </p>
        </span>
      ),
      title: 'Change hearing disposition'
    },
    VACOLS: {
      body: (
        <span>
          <p>
            You are changing the disposition of a hearing being tracked in VACOLS. Please move the location in VACOLS if
            necessary.
          </p>
        </span>
      ),
      title: 'VACOLS hearing disposition'
    }
  };

  cancelButton = () => {
    return (
      <Button linkStyling onClick={this.props.onCancel}>
        Go back
      </Button>
    );
  };

  confirmButton = () => {
    return (
      <Button classNames={['usa-button-secondary']} onClick={this.props.onConfirm}>
        Confirm
      </Button>
    );
  };

  submit = () => {
    this.props.onConfirm();
  };

  render() {
    const { hearing, fromDisposition, toDisposition, onCancel } = this.props;
    const hearingType = hearing.docketName === 'legacy' && !hearing.dispositionEditable ? 'VACOLS' : 'CASEFLOW';

    return (
      <div className="cf-modal-scroll">
        <Modal
          closeHandler={onCancel}
          confirmButton={this.confirmButton()}
          cancelButton={this.cancelButton()}
          title={this.COPY[hearingType].title}
        >
          <div>
            <p>
              Previous Disposition:{' '}
              <strong>{dispositionLabel(fromDisposition)}</strong>
            </p>
            <p>
              New Disposition: <strong>{dispositionLabel(toDisposition)}</strong>
            </p>
          </div>
          {this.COPY[hearingType].body}
        </Modal>
      </div>
    );
  }
}

DispositionModal.propTypes = {
  hearing: PropTypes.object,
  fromDisposition: PropTypes.string,
  toDisposition: PropTypes.string,
  onCancel: PropTypes.func,
  onConfirm: PropTypes.func
};
