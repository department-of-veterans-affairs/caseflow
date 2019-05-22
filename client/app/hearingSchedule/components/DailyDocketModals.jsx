import React from 'react';
import moment from 'moment';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Modal from '../../components/Modal';
import Button from '../../components/Button';

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

export class DispositionModal extends React.Component {

  dispositionMap = {
    postponed: 'Postponed',
    no_show: 'No show',
    held: 'Held',
    cancelled: 'Canceled'
  }

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
                  {hearing.disposition ? this.dispositionMap[fromDisposition] : 'None'}
                </strong>
              </p>
              <p>New Disposition: <strong>{this.dispositionMap[toDisposition]}</strong></p>
            </div>
            {this.COPY[hearingType].body}
          </Modal>
        </div>
      </AppSegment>
    );
  }
}
