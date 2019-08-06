import React from 'react';
import moment from 'moment';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Modal from '../../../components/Modal';
import Button from '../../../components/Button';
import HEARING_DISPOSITION_TYPE_TO_LABEL_MAP from '../../../../constants/HEARING_DISPOSITION_TYPE_TO_LABEL_MAP.json';
import PropTypes from 'prop-types';

export const RemoveHearingModal = ({ onCancelRemoveHearingDay, deleteHearingDay, dailyDocket }) => (
  <div>
    <Modal
      title="Remove Hearing Day"
      closeHandler={onCancelRemoveHearingDay}
      confirmButton={<Button classNames={['usa-button-secondary']} onClick={deleteHearingDay}>
        Confirm
      </Button>}
      cancelButton={<Button linkStyling onClick={onCancelRemoveHearingDay}>Go back</Button>} >
      {'Once the hearing day is removed, users will no longer be able to ' +
        `schedule Veterans for this ${dailyDocket.readableRequestType} hearing day on ` +
        `${moment(dailyDocket.scheduledFor).format('ddd M/DD/YYYY')}.`}
    </Modal>
  </div>
);

RemoveHearingModal.propTypes = {
  onCancelRemoveHearingDay: PropTypes.func,
  deleteHearingDay: PropTypes.func,
  dailyDocket: PropTypes.object
};

export const LockModal = ({ updateLockHearingDay, onCancelDisplayLockModal, dailyDocket }) => (
  <div>
    <Modal
      title={dailyDocket.lock ? 'Unlock Hearing Day' : 'Lock Hearing Day'}
      closeHandler={onCancelDisplayLockModal}
      confirmButton={<Button
        classNames={['usa-button-secondary']}
        onClick={updateLockHearingDay(!dailyDocket.lock)}>
          Confirm
      </Button>}
      cancelButton={<Button linkStyling onClick={onCancelDisplayLockModal}>Go back</Button>} >
      {dailyDocket.lock && 'This hearing day is locked. Do you want to unlock the hearing day'}
      {!dailyDocket.lock &&
        'Completing this action will not allow more Veterans to be scheduled for this day. You can still ' +
        'make changes to the existing slots.'}
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
      cancelButton={<Button linkStyling onClick={onCancel}>Cancel</Button>}
      confirmButton={<Button
        classNames={['usa-button-secondary']}
        onClick={onConfirm}>
          Confirm
      </Button>}>
      This AOD was&nbsp;<strong>{advanceOnDocketMotion.granted ? 'granted' : 'denied'}</strong>&nbsp;on&nbsp;
      {moment(advanceOnDocketMotion.date).format('MM/DD/YYYY')}&nbsp;by Judge&nbsp;{advanceOnDocketMotion.judgeName}.
      &nbsp;Changing this AOD will
    override this previous decision.
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
      body: <span>
        <p>You are changing the hearing disposition for this case.
          Changing the disposition will change where the case is sent next</p>
        <p>The Daily Docket will be locked the day after the hearing date and will
          require administrative access to change after that time.</p>
      </span>,
      title: 'Change hearing disposition'
    },
    VACOLS: {
      body: <span>
        <p>You are changing the disposition of a hearing being tracked in VACOLS.
          Please move the location in VACOLS if necessary.</p>
      </span>,
      title: 'VACOLS hearing disposition'
    }
  }

  cancelButton = () => {
    return <Button linkStyling onClick={this.props.onCancel}>Go back</Button>;
  };

  confirmButton = () => {
    return <Button
      classNames={['usa-button-secondary']}
      onClick={this.props.onConfirm}
    >Confirm
    </Button>;
  };

  submit = () => {
    this.props.onConfirm();
  }

  render () {
    const { hearing, fromDisposition, toDisposition, onCancel } = this.props;
    const hearingType = hearing.docketName === 'legacy' &&
      !hearing.dispositionEditable ? 'VACOLS' : 'CASEFLOW';

    return (
      <AppSegment filledBackground>
        <div className="cf-modal-scroll">
          <Modal
            closeHandler={onCancel}
            confirmButton={this.confirmButton()}
            cancelButton={this.cancelButton()}
            title={this.COPY[hearingType].title}>
            <div>
              <p>
                Previous Disposition: <strong>
                  {hearing.disposition ? HEARING_DISPOSITION_TYPE_TO_LABEL_MAP[fromDisposition] : 'None'}
                </strong>
              </p>
              <p>New Disposition: <strong>{HEARING_DISPOSITION_TYPE_TO_LABEL_MAP[toDisposition]}</strong></p>
            </div>
            {this.COPY[hearingType].body}
          </Modal>
        </div>
      </AppSegment>
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
