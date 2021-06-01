/* eslint-disable max-lines */
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { css } from 'glamor';
import PropTypes from 'prop-types';
import React from 'react';
import { isUndefined, isNil, isEmpty, omitBy, get } from 'lodash';

import HEARING_DISPOSITION_TYPES from '../../../../constants/HEARING_DISPOSITION_TYPES';

import { AodModal } from './DailyDocketModals';
import {
  DispositionDropdown,
  TranscriptRequestedCheckbox,
  HearingDetailsLink,
  AmaAodDropdown,
  LegacyAodDropdown,
  AodReasonDropdown,
  HearingPrepWorkSheetLink,
  StaticRegionalOffice,
  NotesField,
  HearingLocationDropdown,
  StaticHearingDay,
  StaticVirtualHearing,
  Waive90DayHoldCheckbox,
  HoldOpenDropdown
} from './DailyDocketRowInputs';
import { HearingTime } from '../modalForms/HearingTime';
import { deepDiff, isPreviouslyScheduledHearing, pollVirtualHearingData, handleEdit } from '../../utils';
import { docketRowStyle, inputSpacing } from './style';
import { onReceiveAlerts, onReceiveTransitioningAlert, transitionAlert } from '../../../components/common/actions';
import { onUpdateDocketHearing } from '../../actions/dailyDocketActions';
import ApiUtil from '../../../util/ApiUtil';
import Button from '../../../components/Button';
import HearingText from './DailyDocketRowDisplayText';
import VirtualHearingModal from '../VirtualHearingModal';

const SaveButton = ({ hearing, loading, cancelUpdate, saveHearing }) => {
  return (
    <div
      {...css({
        content: ' ',
        clear: 'both',
        display: 'block'
      })}
    >
      <Button styling={css({ float: 'left' })} linkStyling onClick={cancelUpdate}>
        Cancel
      </Button>
      <Button
        styling={css({ float: 'right' })}
        disabled={loading || (hearing?.dateEdited && !hearing?.dispositionEdited)}
        onClick={saveHearing}
      >
        Save
      </Button>
    </div>
  );
};

SaveButton.propTypes = {
  hearing: PropTypes.object,
  loading: PropTypes.bool,
  cancelUpdate: PropTypes.func,
  saveHearing: PropTypes.func
};

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
      loading: false,
      edited: false,
      editedFields: [],
      virtualHearingModalActive: false,
      startPolling: null
    };
  }

  update = (values) => {
    // Determine whether the form has been edited and which fields
    const { edited, editedFields } = handleEdit(this.state.initialState, values, this.state.editedFields);

    // Update the state with the new values
    this.props.update(values);

    // Set the edited value based on a change in initial state
    this.setState({ edited: edited || editedFields.length > 0, editedFields });
  };

  openAodModal = () => {
    this.setState({ aodModalActive: true });
  };

  closeAodModal = () => {
    this.setState({ aodModalActive: false });
  };

  updateAodMotion = (values) => {
    this.update({
      advanceOnDocketMotion: {
        ...(this.props.hearing?.advanceOnDocketMotion || {}),
        ...values
      }
    });
  };

  updateVirtualHearing = (_, values) => {
    this.update({
      virtualHearing: {
        ...(this.props.hearing?.virtualHearing || {}),
        ...values
      }
    });
  };

  openVirtualHearingModal = () => {
    this.setState({ virtualHearingModalActive: true });
  };

  closeVirtualHearingModal = () => {
    this.setState({ virtualHearingModalActive: false });
  };

  cancelUpdate = () => {
    this.props.update(this.state.initialState);
    this.setState({
      edited: false,
      editedFields: [],
      invalid: {
        advanceOnDocketMotionReason: false
      }
    });
  };

  validate = () => {
    const { hearing } = this.props;

    const invalid = {
      advanceOnDocketMotionReason:
        hearing?.advanceOnDocketMotion &&
        !isNil(hearing?.advanceOnDocketMotion.granted) &&
        isNil(hearing?.advanceOnDocketMotion.reason)
    };

    this.setState({ invalid });

    return !invalid.advanceOnDocketMotionReason;
  };

  aodDecidedByAnotherUser = () => {
    const { initialState } = this.state;
    const { user } = this.props;

    if (isNil(initialState.advanceOnDocketMotion) || !user.userHasHearingPrepRole) {
      return false;
    }

    return initialState.advanceOnDocketMotion.userId !== user.userId;
  };

  checkAodAndSave = () => {
    if (this.aodDecidedByAnotherUser()) {
      this.openAodModal();
    } else {
      this.saveHearing();
    }
  };

  processAlerts = (alerts) => {
    alerts.forEach((alert) => {
      if ('hearing' in alert) {
        this.props.onReceiveAlerts(alert.hearing);
      } else if ('virtual_hearing' in alert && !isEmpty(alert.virtual_hearing)) {
        this.props.onReceiveTransitioningAlert(alert.virtual_hearing, 'virtualHearing');
        this.setState({ startPolling: true });
      }
    });
  };

  saveHearing = () => {
    const isValid = this.validate();

    if (!isValid) {
      return;
    }

    const hearingChanges = deepDiff(this.state.initialState, this.props.hearing);
    const locationWasUpdated = !isEmpty(omitBy(hearingChanges?.location, isUndefined));
    const submitData = {
      ...hearingChanges,
      // Always send full location details because a new record is created each update
      location: locationWasUpdated ? this.props.hearing?.location : {}
    };

    this.setState({ loading: true });

    return this.props.
      saveHearing(this.props.hearing?.externalId, submitData).
      then((response) => {
        // false is returned from DailyDocketContainer in case of error
        if (!response) {
          return;
        }

        const alerts = response.body?.alerts;

        if (alerts) {
          this.processAlerts(alerts);
        }

        this.setState({
          initialState: { ...this.props.hearing },
          editedFields: [],
          edited: false
        });
      }).
      finally(() => this.setState({ loading: false }));
  };

  saveThenUpdateDisposition = (toDisposition) => {
    const hearingWithDisp = {
      ...this.props.hearing,
      disposition: toDisposition
    };
    const hearingChanges = deepDiff(this.state.initialState, hearingWithDisp);

    this.setState({ loading: true });

    return this.props.
      saveHearing(hearingWithDisp.externalId, hearingChanges).
      then((response) => {
        // false is returned from DailyDocketContainer in case of error
        if (!response) {
          return;
        }

        const alerts = response.body?.alerts;

        if (alerts) {
          this.processAlerts(alerts);
        }

        this.update(hearingWithDisp);

        if ([HEARING_DISPOSITION_TYPES.postponed, HEARING_DISPOSITION_TYPES.cancelled].indexOf(toDisposition) === -1) {
          this.setState({
            initialState: hearingWithDisp,
            editedFields: [],
            edited: false
          });
        }
      }).
      finally(() => this.setState({ loading: false }));
  };

  isAmaHearing = () => this.props.hearing?.docketName === 'hearing';

  isLegacyHearing = () => this.props.hearing?.docketName === 'legacy';

  getInputProps = () => {
    const { hearing, readOnly } = this.props;

    return {
      hearing,
      readOnly,
      update: this.update
    };
  };

  defaultRightInputs = (rowIndex) => {
    const { hearing, regionalOffice, readOnly } = this.props;
    const inputProps = this.getInputProps();

    return (
      <React.Fragment>
        <StaticRegionalOffice hearing={hearing} />
        <HearingLocationDropdown {...inputProps} regionalOffice={regionalOffice} />
        <StaticHearingDay hearing={hearing} />
        <HearingTime
          {...inputProps}
          disableRadioOptions={hearing?.isVirtual}
          enableZone={hearing?.regionalOfficeTimezone || 'America/New_York'}
          componentIndex={rowIndex}
          regionalOffice={regionalOffice}
          readOnly={
            hearing?.scheduledForIsPast || readOnly || (hearing?.isVirtual && !hearing?.virtualHearing?.jobCompleted)
          }
          onChange={(scheduledTimeString) => {
            this.update({ scheduledTimeString });

            if (scheduledTimeString !== null) {
              this.openVirtualHearingModal();
            }
          }}
          value={hearing?.scheduledTimeString}
        />
      </React.Fragment>
    );
  };

  judgeRightInputs = () => {
    const { hearing, user } = this.props;
    const inputProps = this.getInputProps();

    return (
      <React.Fragment>
        <HearingPrepWorkSheetLink hearing={hearing} />
        {this.isAmaHearing() && (
          <React.Fragment>
            <AmaAodDropdown {...inputProps} updateAodMotion={this.updateAodMotion} userId={user.userId} />
            <AodReasonDropdown
              {...inputProps}
              updateAodMotion={this.updateAodMotion}
              userId={user.userId}
              invalid={this.state.invalid.advanceOnDocketMotionReason}
            />
          </React.Fragment>
        )}
        {this.isLegacyHearing() && (
          <React.Fragment>
            <LegacyAodDropdown {...inputProps} />
            <HoldOpenDropdown {...inputProps} />
          </React.Fragment>
        )}
      </React.Fragment>
    );
  };

  getRightColumn = (rowIndex) => {
    const inputs = this.props.user.userHasHearingPrepRole ?
      this.judgeRightInputs() :
      this.defaultRightInputs(rowIndex);

    return (
      <div {...inputSpacing}>
        {inputs}
        {this.state.edited && (
          <SaveButton
            hearing={this.props.hearing}
            loading={this.state.loading}
            cancelUpdate={this.cancelUpdate}
            saveHearing={this.checkAodAndSave}
          />
        )}
      </div>
    );
  };

  getLeftColumn = () => {
    const { hearing, user, openDispositionModal, readOnly } = this.props;
    const inputProps = this.getInputProps();

    return (
      <div {...inputSpacing}>
        {hearing?.isVirtual && <StaticVirtualHearing hearing={hearing} user={user} />}
        <DispositionDropdown
          {...inputProps}
          cancelUpdate={this.cancelUpdate}
          saveHearing={this.saveThenUpdateDisposition}
          openDispositionModal={openDispositionModal}
          readOnly={readOnly || (hearing?.isVirtual && !hearing?.virtualHearing?.jobCompleted)}
        />
        {user.userHasHearingPrepRole && this.isAmaHearing() && <Waive90DayHoldCheckbox {...inputProps} />}
        <TranscriptRequestedCheckbox {...inputProps} />
        {user.userCanAssignHearingSchedule && !user.userHasHearingPrepRole && <HearingDetailsLink hearing={hearing} />}
        <NotesField {...inputProps} readOnly={user.userCanVsoHearingSchedule} />
      </div>
    );
  };

  startPolling = () => {
    return pollVirtualHearingData(this.props.hearing?.externalId, (response) => {
      const resp = ApiUtil.convertToCamelCase(response);

      if (resp.virtualHearing?.jobCompleted) {
        this.setState({ startPolling: false, edited: false, editedFields: [] });
        this.updateVirtualHearing(null, resp.virtualHearing);

        this.props.transitionAlert('virtualHearing');
      }

      // continue polling if return true (opposite of jobCompleted)
      return !resp.virtualHearing?.jobCompleted;
    });
  };

  renderVirtualHearingModal = (user, hearing) => (
    <VirtualHearingModal
      closeModal={this.closeVirtualHearingModal}
      hearing={hearing}
      timeWasEdited={this.state.initialState.scheduledTimeString !== get(hearing, 'scheduledTimeString')}
      virtualHearing={hearing?.virtualHearing || {}}
      reset={() => {
        this.update({ scheduledTimeString: this.state.initialState.scheduledTimeString });
      }}
      user={user}
      update={this.updateVirtualHearing}
      submit={this.saveHearing}
      type="change_hearing_time"
    />
  );

  render() {
    const { hearing, user, index, readOnly, hidePreviouslyScheduled } = this.props;

    const previous = isPreviouslyScheduledHearing(hearing) && hidePreviouslyScheduled;
    const scheduledInError = hearing?.disposition === HEARING_DISPOSITION_TYPES.scheduled_in_error;

    const hide = (previous || scheduledInError) ? 'hide ' : '';
    const judgeView = user.userHasHearingPrepRole ? 'judge-view' : '';
    const className = `${hide}${judgeView}`;

    return (
      <div {...docketRowStyle} key={hearing?.externalId} className={className}>
        <div>
          <HearingText
            readOnly={readOnly}
            update={this.update}
            hearing={hearing}
            initialState={this.state.initialState}
            user={user}
            index={index}
          />
        </div>
        <div>
          {this.getLeftColumn()}
          {this.getRightColumn(index)}
        </div>
        {user.userCanScheduleVirtualHearings &&
          this.state.virtualHearingModalActive &&
          hearing?.isVirtual &&
          this.renderVirtualHearingModal(user, hearing)}
        {this.state.aodModalActive && (
          <AodModal
            advanceOnDocketMotion={hearing?.advanceOnDocketMotion || {}}
            onConfirm={() => {
              this.saveHearing();
              this.closeAodModal();
            }}
            onCancel={() => {
              this.updateAodMotion(this.state.initialState.advanceOnDocketMotion);
              this.closeAodModal();
            }}
          />
        )}
        {this.state.startPolling && this.startPolling()}
      </div>
    );
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
    regionalOfficeTimezone: PropTypes.string,
    docketName: PropTypes.string,
    advanceOnDocketMotion: PropTypes.object,
    virtualHearing: PropTypes.shape({
      jobCompleted: PropTypes.bool
    }),
    isVirtual: PropTypes.bool,
    externalId: PropTypes.string,
    disposition: PropTypes.string,
    scheduledForIsPast: PropTypes.bool,
    scheduledTimeString: PropTypes.string
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
  onReceiveTransitioningAlert: PropTypes.func,
  transitionAlert: PropTypes.func
};

const mapStateToProps = (state, props) => ({
  hearing: props.hearingId ? state.dailyDocket.hearings[props.hearingId] : {}
});

const mapDispatchToProps = (dispatch, props) =>
  bindActionCreators(
    {
      update: (values) => onUpdateDocketHearing(props.hearingId, values),
      onReceiveAlerts,
      onReceiveTransitioningAlert,
      transitionAlert
    },
    dispatch
  );

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(DailyDocketRow);
