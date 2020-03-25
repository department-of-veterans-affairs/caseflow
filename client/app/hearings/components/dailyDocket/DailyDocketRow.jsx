import React from 'react';
import { css } from 'glamor';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import _ from 'lodash';

import Button from '../../../components/Button';

import { onUpdateDocketHearing } from '../../actions/dailyDocketActions';
import { AodModal } from './DailyDocketModals';
import HearingText from './DailyDocketRowDisplayText';
import PropTypes from 'prop-types';
import { deepDiff, isPreviouslyScheduledHearing } from '../../utils';
import { onReceiveAlerts, removeAlertsWithoutExpiration } from '../../../components/common/actions';
import ExponentialPolling from '../../../components/ExponentialPolling';
import {
  DispositionDropdown, TranscriptRequestedCheckbox, HearingDetailsLink,
  AmaAodDropdown, LegacyAodDropdown, AodReasonDropdown, HearingPrepWorkSheetLink, StaticRegionalOffice,
  NotesField, HearingLocationDropdown, StaticHearingDay, StaticVirtualHearing, TimeRadioButtons,
  Waive90DayHoldCheckbox, HoldOpenDropdown
} from './DailyDocketRowInputs';
import VirtualHearingModal from '../VirtualHearingModal';
import { docketRowStyle } from './style';

const SaveButton = ({ hearing, cancelUpdate, saveHearing }) => {
  return <div {...css({
    content: ' ',
    clear: 'both',
    display: 'block'
  })}>
    <Button
      styling={css({ float: 'left' })}
      linkStyling
      onClick={cancelUpdate}>
      Cancel
    </Button>
    <Button
      styling={css({ float: 'right' })}
      disabled={hearing.dateEdited && !hearing.dispositionEdited}
      onClick={saveHearing}>
      Save
    </Button>
  </div>;
};

SaveButton.propTypes = {
  hearing: PropTypes.object,
  cancelUpdate: PropTypes.func,
  saveHearing: PropTypes.func
};

const inputSpacing = css({
  '&>div:not(:first-child)': {
    marginTop: '25px'
  }
});

class DailyDocketRow extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      initialState: {
        ...props.hearing
      },
      invalid: {
        advanceOnDocketMotionReason: false
      },
      aodModalActive: false,
      edited: false,
      virtualHearingModalActive: false,
      virtualHearingJobStarted: null
    };
  }

  update = (values) => {
    this.props.update(values);
    this.setState({ edited: true });
  }

  openAodModal = () => {
    this.setState({ aodModalActive: true });
  }

  closeAodModal = () => {
    this.setState({ aodModalActive: false });
  }

  updateAodMotion = (values) => {
    this.update({
      advanceOnDocketMotion: {
        ...(this.props.hearing.advanceOnDocketMotion || {}),
        ...values
      }
    });
  }

  updateVirtualHearing = (values) => {
    this.update({
      virtualHearing: {
        ...(this.props.hearing.virtualHearing || {}),
        ...values
      }
    });
  }

  openVirtualHearingModal = () => {
    this.setState({ virtualHearingModalActive: true });
  }

  closeVirtualHearingModal = () => {
    this.setState({ virtualHearingModalActive: false });
  }

  cancelUpdate = () => {
    this.props.update(this.state.initialState);
    this.setState({
      edited: false,
      invalid: {
        advanceOnDocketMotionReason: false
      }
    });
  }

  validate = () => {
    const { hearing } = this.props;

    const invalid = {
      advanceOnDocketMotionReason: hearing.advanceOnDocketMotion &&
        !_.isNil(hearing.advanceOnDocketMotion.granted) &&
        _.isNil(hearing.advanceOnDocketMotion.reason)
    };

    this.setState({ invalid });

    return !invalid.advanceOnDocketMotionReason;
  }

  aodDecidedByAnotherUser = () => {
    const { initialState } = this.state;
    const { user } = this.props;

    if (_.isNil(initialState.advanceOnDocketMotion) || !user.userHasHearingPrepRole) {
      return false;
    }

    return initialState.advanceOnDocketMotion.userId !== user.userId;
  }

  checkAodAndSave = () => {
    if (this.aodDecidedByAnotherUser()) {
      this.openAodModal();
    } else {
      this.saveHearing();
    }
  }

  saveHearing = () => {
    const isValid = this.validate();

    if (!isValid) {
      return;
    }

    const hearing = deepDiff(this.state.initialState, this.props.hearing);

    return this.props.saveHearing(this.props.hearing.externalId, hearing).
      then((response) => {
        if (response) {
          const alerts = response.body.alerts;

          // if user is sitting on the page after making changes to virtual hearing
          // poll job_completed status to let the user know that changes have been made.
          // Since we don't want to start polling every time the user hits submit, we
          // check if the hearing is virtual and the hearing time was modified.
          if (this.state.initialState.isVirtual && hearing.scheduledTimeString) {
            this.setState({ virtualHearingJobStarted: true });
            this.setState({ alerts: alerts.filter((alert) => alert.type === 'success' && !alert.autoClear) });
          }

          this.props.onReceiveAlerts(
            alerts.filter((alert) => (alert.type === 'success' && alert.autoClear) || alert.type === 'info')
          );
          this.setState({
            initialState: { ...this.props.hearing },
            edited: false
          });
        }
      });
  }

  isAmaHearing = () => this.props.hearing.docketName === 'hearing'

  isLegacyHearing = () => this.props.hearing.docketName === 'legacy'

  getInputProps = () => {
    const { hearing, readOnly } = this.props;

    return {
      hearing,
      readOnly,
      update: this.update
    };
  }

  defaultRightInputs = () => {
    const { hearing, regionalOffice, readOnly } = this.props;
    const inputProps = this.getInputProps();

    return <React.Fragment>
      <StaticRegionalOffice hearing={hearing} />
      <HearingLocationDropdown {...inputProps} regionalOffice={regionalOffice} />
      <StaticHearingDay hearing={hearing} />
      <TimeRadioButtons {...inputProps} regionalOffice={regionalOffice}
        readOnly={(hearing.scheduledForIsPast || readOnly) ||
          (hearing.isVirtual && !hearing.virtualHearing.jobCompleted)}
        update={(values) => {
          this.update(values);
          if (values.scheduledTimeString !== null) {
            this.openVirtualHearingModal();
          }
        }} />
    </React.Fragment>;
  }

  judgeRightInputs = () => {
    const { hearing, user } = this.props;
    const inputProps = this.getInputProps();

    return <React.Fragment>
      <HearingPrepWorkSheetLink hearing={hearing} />
      {this.isAmaHearing() && <React.Fragment>
        <AmaAodDropdown {...inputProps} updateAodMotion={this.updateAodMotion} userId={user.userId} />
        <AodReasonDropdown {...inputProps}
          updateAodMotion={this.updateAodMotion}
          userId={user.userId}
          invalid={this.state.invalid.advanceOnDocketMotionReason} />
      </React.Fragment>}
      {this.isLegacyHearing() && <React.Fragment>
        <LegacyAodDropdown {...inputProps} />
        <HoldOpenDropdown {...inputProps} />
      </React.Fragment>}
    </React.Fragment>;
  }

  getRightColumn = () => {
    const inputs = this.props.user.userHasHearingPrepRole ? this.judgeRightInputs() : this.defaultRightInputs();

    return <div {...inputSpacing}>
      {inputs}
      {this.state.edited &&
        <SaveButton
          hearing={this.props.hearing}
          cancelUpdate={this.cancelUpdate}
          saveHearing={this.checkAodAndSave} />}
    </div>;
  }

  getLeftColumn = () => {
    const { hearing, user, openDispositionModal, readOnly } = this.props;
    const inputProps = this.getInputProps();

    return (
      <div {...inputSpacing}>
        {hearing.isVirtual &&
          <StaticVirtualHearing hearing={hearing} user={user} />
        }
        <DispositionDropdown {...inputProps}
          cancelUpdate={this.cancelUpdate}
          saveHearing={this.saveHearing}
          openDispositionModal={openDispositionModal}
          readOnly={readOnly || (hearing.isVirtual && !hearing.virtualHearing.jobCompleted)} />
        {(user.userHasHearingPrepRole && this.isAmaHearing()) &&
          <Waive90DayHoldCheckbox {...inputProps} />}
        <TranscriptRequestedCheckbox {...inputProps} />
        {(user.userCanAssignHearingSchedule && !user.userHasHearingPrepRole) &&
          <HearingDetailsLink hearing={hearing} />
        }
        <NotesField {...inputProps} readOnly={user.userCanVsoHearingSchedule} />
      </div>
    );
  }

  pollVirtualHearingData = () => (
    // Did not specify retryCount so if api call fails, it'll stop polling.
    // If need to retry on failure, pass in retryCount
    <ExponentialPolling
      url={`/hearings/${this.props.hearing.externalId}/virtual_hearing_job_status`}
      method="GET"
      interval={1000}
      backoffMultiplier={3}
      onSuccess={(response) => {
        if (response.job_completed) {
          this.updateVirtualHearing({ jobCompleted: response.job_completed });
          // remove in-progress alert
          this.props.removeAlertsWithoutExpiration();
          // show success alert
          this.props.onReceiveAlerts(this.state.alerts);
          this.setState({ virtualHearingJobStarted: false });
        }

        // continue polling if return true (opposite of job_completed)
        return !response.job_completed;
      }}
      render={() => null}
    />
  )

  renderVirtualHearingModal = (user, hearing) => (
    <VirtualHearingModal hearing={hearing}
      timeWasEdited={this.state.initialState.scheduledTimeString !== _.get(hearing, 'scheduledTimeString')}
      virtualHearing={hearing.virtualHearing || {}} reset={() => {
        this.update({ scheduledTimeString: this.state.initialState.scheduledTimeString });
        this.closeVirtualHearingModal()
        ;
      }} user={user}
      update={this.updateVirtualHearing}
      submit={() => this.saveHearing().then(this.closeVirtualHearingModal)}
      type="change_hearing_time"
    />
  )

  render () {
    const { hearing, user, index, readOnly, hidePreviouslyScheduled } = this.props;

    const hide = (isPreviouslyScheduledHearing(hearing) && hidePreviouslyScheduled) ? 'hide ' : '';
    const judgeView = user.userHasHearingPrepRole ? 'judge-view' : '';
    const className = `${hide}${judgeView}`;

    return <div {...docketRowStyle} key={hearing.externalId} className={className}>
      <div>
        <HearingText
          readOnly={readOnly}
          update={this.update}
          hearing={hearing}
          initialState={this.state.initialState}
          user={user}
          index={index} />
      </div>
      <div>
        {this.getLeftColumn()}
        {this.getRightColumn()}
      </div>
      {(user.userCanScheduleVirtualHearings && this.state.virtualHearingModalActive && hearing.isVirtual) &&
        this.renderVirtualHearingModal(user, hearing)}
      {this.state.aodModalActive && <AodModal
        advanceOnDocketMotion={hearing.advanceOnDocketMotion || {}}
        onConfirm={() => {
          this.saveHearing();
          this.closeAodModal();
        }}
        onCancel={() => {
          this.updateAodMotion(this.state.initialState.advanceOnDocketMotion);
          this.closeAodModal();
        }}
      />}
      {this.state.virtualHearingJobStarted && this.pollVirtualHearingData()}
    </div>;
  }
}

DailyDocketRow.propTypes = {
  index: PropTypes.number,
  hearingId: PropTypes.string,
  update: PropTypes.func,
  saveHearing: PropTypes.func,
  openDispositionModal: PropTypes.func,
  regionalOffice: PropTypes.string,
  readOnly: PropTypes.bool,
  hidePreviouslyScheduled: PropTypes.bool,
  hearing: PropTypes.shape({
    docketName: PropTypes.string,
    advanceOnDocketMotion: PropTypes.object,
    virtualHearing: PropTypes.shape({
      jobCompleted: PropTypes.bool
    }),
    isVirtual: PropTypes.bool,
    externalId: PropTypes.string,
    disposition: PropTypes.string,
    scheduledForIsPast: PropTypes.bool
  }),
  user: PropTypes.shape({
    userCanAssignHearingSchedule: PropTypes.bool,
    userCanBuildHearingSchedule: PropTypes.bool,
    userCanViewHearingSchedule: PropTypes.bool,
    userCanVsoHearingSchedule: PropTypes.bool,
    userHasHearingPrepRole: PropTypes.bool,
    userInHearingOrTranscriptionOrganization: PropTypes.bool,
    userCanScheduleVirtualHearings: PropTypes.bool,
    userId: PropTypes.number,
    userCssId: PropTypes.string
  }),
  onReceiveAlerts: PropTypes.func,
  removeAlertsWithoutExpiration: PropTypes.func
};

const mapStateToProps = (state, props) => ({
  hearing: props.hearingId ? state.dailyDocket.hearings[props.hearingId] : {}
});

const mapDispatchToProps = (dispatch, props) => bindActionCreators({
  update: (values) => onUpdateDocketHearing(props.hearingId, values),
  onReceiveAlerts,
  removeAlertsWithoutExpiration
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(DailyDocketRow);
