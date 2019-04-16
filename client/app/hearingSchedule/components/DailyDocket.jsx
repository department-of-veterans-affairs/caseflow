import React from 'react';
import PropTypes from 'prop-types';
import moment from 'moment';
import { css } from 'glamor';
import _ from 'lodash';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import Button from '../../components/Button';
import Alert from '../../components/Alert';
import Modal from '../../components/Modal';
import DispositionModal from './DailyDocketDispositionModal';
import StatusMessage from '../../components/StatusMessage';
import { crossSymbolHtml, pencilSymbol, lockIcon } from '../../components/RenderFunctions';
import { getHearingAppellantName } from './DailyDocketRowDisplayText';

import DailyDocketRows from './DailyDocketRows';

const alertStyling = css({
  marginBottom: '30px'
});

const Alerts = ({
  saveSuccessful, displayLockSuccessMessage, onErrorHearingDayLock, dailyDocket, dailyDocketServerError
}) => (
  <React.Fragment>
    {saveSuccessful &&
      <Alert type="success"
        styling={alertStyling}
        title={`You have successfully updated ${getHearingAppellantName(saveSuccessful)}'s hearing.`} />}

    {displayLockSuccessMessage &&
      <Alert type="success"
        styling={alertStyling}
        title={dailyDocket.lock ? 'You have successfully locked this Hearing ' +
          'Day' : 'You have successfully unlocked this Hearing Day'}
        message={dailyDocket.lock ? 'You cannot add more veterans to this hearing day, ' +
          'but you can edit existing entries' : 'You can now add more veterans to this hearing day'} />}

    {dailyDocketServerError &&
      <Alert type="error"
        styling={alertStyling}
        title=" This save was unsuccessful."
        message="Please refresh the page and try again." />}

    {onErrorHearingDayLock &&
      <Alert type="error"
        styling={alertStyling}
        title={`VACOLS Hearing Day ${moment(dailyDocket.scheduledFor).format('M/DD/YYYY')}
           cannot be locked in Caseflow.`}
        message="VACOLS Hearing Day cannot be locked" />}
  </React.Fragment>
);

const EditDailyDocket = ({
  dailyDocket, openModal, onDisplayLockModal, hasHearings,
  onClickRemoveHearingDay, user
}) => (
  <React.Fragment>
    <h1>Daily Docket ({moment(dailyDocket.scheduledFor).format('ddd M/DD/YYYY')})</h1><br />
    <div {...css({
      marginTop: '-35px',
      marginBottom: '25px'
    })}>
      <Link linkStyling to="/schedule" >&lt; Back to schedule</Link>&nbsp;&nbsp;
      {user.userRoleAssign &&
        <span>
          <Button {...css({ marginLeft: '30px' })} linkStyling onClick={openModal} >
            <span {...css({ position: 'absolute' })}>{pencilSymbol()}</span>
            <span {...css({
              marginRight: '5px',
              marginLeft: '20px'
            })}>
                Edit Hearing Day
            </span>
          </Button>
          &nbsp;&nbsp;
          <Button linkStyling onClick={onDisplayLockModal}>
            <span {...css({ position: 'absolute',
              '& > svg > g > g': { fill: '#0071bc' } })}>
              {lockIcon()}
            </span>
            <span {...css({ marginRight: '5px',
              marginLeft: '16px' })}>
              {dailyDocket.lock ? 'Unlock Hearing Day' : 'Lock Hearing Day'}
            </span>
          </Button>
          &nbsp;&nbsp;
        </span>}
      {(!hasHearings && user.userRoleBuild) &&
        <Button
          linkStyling
          onClick={onClickRemoveHearingDay} >
          {crossSymbolHtml()}<span{...css({ marginLeft: '3px' })}>Remove Hearing Day</span>
        </Button>}
      {dailyDocket.notes &&
        <span {...css({ marginTop: '15px' })}>
          <br /><strong>Notes: </strong>
          <br />{dailyDocket.notes}
        </span>}
    </div>
  </React.Fragment>
);

const RemoveHearingModal = ({ onCancelRemoveHearingDay, deleteHearingDay, dailyDocket }) => (
  <div>
    <Modal
      title="Remove Hearing Day"
      closeHandler={onCancelRemoveHearingDay}
      confirmButton={<Button classNames={['usa-button-secondary']} onClick={deleteHearingDay}>
        Confirm
      </Button>}
      cancelButton={<Button linkStyling onClick={onCancelRemoveHearingDay}>Go back</Button>} >
      {'Once the hearing day is removed, users will no longer be able to ' +
        `schedule Veterans for this ${dailyDocket.requestType} hearing day on ` +
        `${moment(dailyDocket.scheduledFor).format('ddd M/DD/YYYY')}.`}
    </Modal>
  </div>
);

const LockModal = ({ updateLockHearingDay, onCancelDisplayLockModal, dailyDocket }) => (
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

export default class DailyDocket extends React.Component {
  constructor (props) {
    super(props);

    this.state = {
      editedDispositionModalProps: null
    };
  }
  onInvalidForm = (hearingId) => (invalid) => this.props.onInvalidForm(hearingId, invalid);

  previouslyScheduled = (hearing) => {
    return hearing.disposition === 'postponed' || hearing.disposition === 'cancelled';
  };

  previouslyScheduledHearings = () => {
    return _.filter(this.props.hearings, (hearing) => this.previouslyScheduled(hearing));
  };

  dailyDocketHearings = () => {
    return _.filter(this.props.hearings, (hearing) => !this.previouslyScheduled(hearing));
  };

  getRegionalOffice = () => {
    const { dailyDocket } = this.props;

    return dailyDocket.requestType === 'Central' ? 'C' : dailyDocket.regionalOfficeKey;
  };

  openDispositionModal = ({ hearing, disposition, onConfirm }) => {
    this.setState({
      editedDispositionModalProps: {
        hearing,
        disposition,
        onConfirm: () => {
          onConfirm();
          this.closeDispositionModal();
        }
      }
    });
  }

  closeDispositionModal = () => {
    this.setState({ editedDispositionModalProps: null });
  }

  saveHearing = (hearingId) => {
    setTimeout(() => {
      // this ensures we're updating with the latest hearing data
      // after Redux update
      const hearing = this.props.hearings[hearingId];

      this.props.saveHearing(hearing);
    }, 0);
  }

  render() {

    const regionalOffice = this.getRegionalOffice();
    const hasHearings = !_.isEmpty(this.props.hearings);

    const {
      dailyDocket, onClickRemoveHearingDay, displayRemoveHearingDayModal, displayLockModal, openModal,
      deleteHearingDay, updateLockHearingDay, onCancelDisplayLockModal, user
    } = this.props;

    const { editedDispositionModalProps } = this.state;

    return <AppSegment filledBackground>

      {editedDispositionModalProps &&
        <DispositionModal
          {...this.state.editedDispositionModalProps}
          onCancel={this.closeDispositionModal} />}

      {displayRemoveHearingDayModal &&
        <RemoveHearingModal dailyDocket={dailyDocket}
          onClickRemoveHearingDay={onClickRemoveHearingDay}
          deleteHearingDay={deleteHearingDay} />}

      {displayLockModal &&
        <LockModal
          dailyDocket={dailyDocket}
          updateLockHearingDay={updateLockHearingDay}
          onCancelDisplayLockModal={onCancelDisplayLockModal} />}

      <Alerts
        dailyDocket={dailyDocket}
        saveSuccessful={this.props.saveSuccessful}
        displayLockSuccessMessage={this.props.displayLockSuccessMessage}
        dailyDocketServerError={this.props.dailyDocketServerError}
        onErrorHearingDayLock={this.props.onErrorHearingDayLock} />

      <div className="cf-app-segment">
        <div className="cf-push-left">
          <EditDailyDocket
            dailyDocket={dailyDocket}
            user={user}
            openModal={openModal}
            onDisplayLockModal={this.props.onDisplayLockModal}
            hasHearings={hasHearings}
            onClickRemoveHearingDay={this.props.onClickRemoveHearingDay} />
        </div>
        <div className="cf-push-right">
          VLJ: {dailyDocket.judgeFirstName} {dailyDocket.judgeLastName} <br />
          Coordinator: {dailyDocket.bvaPoc} <br />
          Hearing type: {dailyDocket.requestType} <br />
          Regional office: {dailyDocket.regionalOffice}<br />
          Room number: {dailyDocket.room}
        </div>
      </div>

      {hasHearings &&
        <DailyDocketRows
          hearings={this.dailyDocketHearings()}
          readOnly={user.userRoleView || user.userRoleVso}
          onHearingNotesUpdate={this.props.onHearingNotesUpdate}
          onHearingDispositionUpdate={this.props.onHearingDispositionUpdate}
          onHearingTimeUpdate={this.props.onHearingTimeUpdate}
          onTranscriptRequestedUpdate={this.props.onTranscriptRequestedUpdate}
          onHearingLocationUpdate={this.props.onHearingLocationUpdate}
          cancelHearingUpdate={this.props.onCancelHearingUpdate}
          saveHearing={this.saveHearing}
          openDispositionModal={this.openDispositionModal}
          regionalOffice={regionalOffice}
          user={user} />}

      {!hasHearings &&
        <div {...css({ marginTop: '75px' })}>
          <StatusMessage
            title= "No Veterans are scheduled for this hearing day."
            type="status" />
        </div>}

      {!_.isEmpty(this.previouslyScheduledHearings()) &&
        <div {...css({ marginTop: '75px' })}>
          <h1>Previously Scheduled</h1>
          <DailyDocketRows
            hearings={this.previouslyScheduledHearings()}
            regionalOffice={regionalOffice}
            user={user}
            readOnly />
        </div>}
    </AppSegment>;
  }
}

DailyDocket.propTypes = {
  dailyDocket: PropTypes.object,
  hearings: PropTypes.object,
  onHearingNotesUpdate: PropTypes.func,
  onHearingDispositionUpdate: PropTypes.func,
  onHearingTimeUpdate: PropTypes.func,
  onHearingRegionalOfficeUpdate: PropTypes.func,
  onInvalidForm: PropTypes.func,
  openModal: PropTypes.func,
  deleteHearingDay: PropTypes.func,
  notes: PropTypes.string
};
