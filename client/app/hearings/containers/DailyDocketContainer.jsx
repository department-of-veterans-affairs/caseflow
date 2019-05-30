import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { withRouter } from 'react-router-dom';
import _ from 'lodash';

import { LOGO_COLORS } from '../../constants/AppConstants';
import LoadingDataDisplay from '../../components/LoadingDataDisplay';
import ApiUtil from '../../util/ApiUtil';
import {
  onReceiveDailyDocket,
  onReceiveHearing,
  onReceiveSavedHearing,
  onResetSaveSuccessful,
  selectHearingRoom,
  selectVlj,
  selectHearingCoordinator,
  setNotes,
  onHearingDayModified,
  onClickRemoveHearingDay,
  onCancelRemoveHearingDay,
  onSuccessfulHearingDayDelete,
  onDisplayLockModal,
  onCancelDisplayLockModal,
  onUpdateLock,
  onResetLockSuccessMessage,
  handleDailyDocketServerError,
  onResetDailyDocketAfterError,
  handleLockHearingServerError,
  onResetLockHearingAfterError
} from '../actions/dailyDocketActions';
import DailyDocket from '../components/dailyDocket/DailyDocket';
import DailyDocketPrinted from '../components/dailyDocket/DailyDocketPrinted';
import HearingDayEditModal from '../components/HearingDayEditModal';
import Alert from '../../components/Alert';

export class DailyDocketContainer extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      modalOpen: false,
      showModalAlert: false,
      serverError: false
    };
  }

  componentDidUpdate = (prevProps) => {
    if (!((_.isNil(prevProps.saveSuccessful) && this.props.saveSuccessful) || _.isNil(this.props.saveSuccessful))) {
      this.props.onResetSaveSuccessful();
    }
    if (!((_.isNil(prevProps.displayLockSuccessMessage) && this.props.displayLockSuccessMessage) ||
        _.isNil(this.props.displayLockSuccessMessage))) {
      this.props.onResetLockSuccessMessage();
    }
    if (!((_.isNil(prevProps.dailyDocketServerError) && this.props.dailyDocketServerError) ||
      _.isNil(this.props.dailyDocketServerError))) {
      this.props.onResetDailyDocketAfterError();
    }
    if (!((_.isNil(prevProps.onErrorHearingDayLock) && this.props.onErrorHearingDayLock) ||
      _.isNil(this.props.onErrorHearingDayLock))) {
      this.props.onResetLockHearingAfterError();
    }
  };

  componentWillUnmount = () => {
    this.props.onResetSaveSuccessful();
    this.props.onCancelRemoveHearingDay();
    this.props.onResetDailyDocketAfterError();
    this.props.onResetLockHearingAfterError();
  };

  loadHearingDetails = (hearings) => {
    _.each(hearings, (hearing) => {
      ApiUtil.get(`/hearings/${hearing.externalId}`).then((response) => {
        const resp = ApiUtil.convertToCamelCase(JSON.parse(response.text));

        this.props.onReceiveHearing(resp);
      }).
        catch((error) => {
          console.log(`Hearing endpoint failed with: ${error}`); // eslint-disable-line no-console
        });
    });
  }

  loadHearingDay = () => {
    const requestUrl = `/hearings/hearing_day/${this.props.match.params.hearingDayId}`;

    return ApiUtil.get(requestUrl).then((response) => {
      const resp = ApiUtil.convertToCamelCase(JSON.parse(response.text));

      const hearings = _.keyBy(resp.hearingDay.hearings, 'externalId');
      const hearingDay = _.omit(resp.hearingDay, ['hearings']);

      this.props.onReceiveDailyDocket(hearingDay, hearings);

      this.loadHearingDetails(resp.hearingDay.hearings);
    });
  };

  formatHearing = (hearing) => {
    const amaHearingValues = hearing.docketName === 'hearing' ? {
      evidence_window_waived: hearing.evidenceWindowWaived
    } : {};

    const legacyValues = hearing.docketName === 'legacy' ? {
      aod: hearing.aod,
      hold_open: hearing.holdOpen
    } : {};

    return _.omitBy({
      disposition: hearing.disposition,
      transcript_requested: hearing.transcriptRequested,
      notes: hearing.notes,
      hearing_location_attributes: hearing.location ? ApiUtil.convertToSnakeCase(hearing.location) : null,
      scheduled_time_string: hearing.scheduledTimeString,
      prepped: hearing.prepped,
      ...legacyValues,
      ...amaHearingValues
    }, _.isNil);
  };

  formatAod = (hearing) => {
    if (hearing.advanceOnDocketMotion.userId !== this.props.user.userId) {
      return {};
    }

    return _.omitBy({
      reason: hearing.advanceOnDocketMotion.reason,
      granted: hearing.advanceOnDocketMotion.granted,
      person_id: hearing.claimantId || hearing.advanceOnDocketMotion.personId,
      user_id: hearing.advanceOnDocketMotion.userId
    }, _.isNil);
  }

  saveHearing = (hearingId) => {
    const hearing = this.props.hearings[hearingId];
    const aodMotion = hearing.advanceOnDocketMotion ? {
      advance_on_docket_motion: this.formatAod(hearing)
    } : {};

    return ApiUtil.patch(`/hearings/${hearing.externalId}`, { data: {
      hearing: this.formatHearing(hearing),
      ...aodMotion
    } }).
      then((response) => {
        const resp = ApiUtil.convertToCamelCase(JSON.parse(response.text));

        this.props.onReceiveSavedHearing(resp);

        return true;
      }, (err) => {
        this.props.handleDailyDocketServerError(err);

        return false;
      });
  };

  updateLockHearingDay = (lock) => () => {
    ApiUtil.patch(`/hearings/hearing_day/${this.props.hearingDay.id}`, { data: { lock } }).
      then(() => {
        this.props.onUpdateLock(lock);
      }, (err) => {
        this.props.handleLockHearingServerError(err);
      });
  };

  deleteHearingDay = () => {
    ApiUtil.delete(`/hearings/hearing_day/${this.props.hearingDay.id}`).
      then(() => {
        this.props.onSuccessfulHearingDayDelete(this.props.hearingDay.scheduledFor);
        this.props.history.push('/schedule');
      }, (err) => {
        this.props.handleDailyDocketServerError(err);
      });
  };

  createHearingPromise = () => Promise.all([
    this.loadHearingDay()
  ]);

  openModal = () => {
    this.setState({ showModalAlert: false,
      modalOpen: true });
  };

  closeModal = () => {
    this.setState({ modalOpen: false });

    if (this.props.hearingDayModified) {
      this.setState({ showModalAlert: true });

      let data = { id: this.props.hearingDay.id };

      if (this.props.hearingRoom) {
        data.room = this.props.hearingRoom.value;
      }

      if (this.props.vlj) {
        data.judge_id = this.props.vlj.value;
      }

      if (this.props.coordinator) {
        data.bva_poc = this.props.coordinator.value;
      }

      if (this.props.notes) {
        data.notes = this.props.notes;
      }

      ApiUtil.put(`/hearings/hearing_day/${this.props.hearingDay.id}`, { data }).
        then((response) => {
          const editedHearingDay = ApiUtil.convertToCamelCase(JSON.parse(response.text));

          editedHearingDay.requestType = this.props.hearingDay.requestType;

          this.props.onReceiveDailyDocket(editedHearingDay, this.props.hearings);
        }, () => {
          this.setState({ serverError: true });
        });
    }
  };

  cancelModal = () => {
    this.setState({ modalOpen: false });
  };

  getAlertTitle = () => {
    if (this.state.serverError) {
      return 'An Error Occurred';
    }

    return 'You have successfully completed this action';
  };

  getAlertMessage = () => {
    if (this.state.serverError) {
      return 'You are unable to complete this action.';
    }

    return <p>You can view your new updates, listed below</p>;
  };

  getAlertType = () => {
    if (this.state.serverError) {
      return 'error';
    }

    return 'success';
  };

  render() {
    const loadingDataDisplay = <LoadingDataDisplay
      createLoadPromise={this.createHearingPromise}
      loadingComponentProps={{
        spinnerColor: LOGO_COLORS.HEARINGS.ACCENT,
        message: 'Loading the daily docket...'
      }}
      failStatusMessageProps={{
        title: 'Unable to load the daily docket.'
      }}
    >
      {this.state.showModalAlert &&
        <Alert type={this.getAlertType()} title={this.getAlertTitle()} scrollOnAlert={false}>
          {this.getAlertMessage()}
        </Alert>
      }

      {this.props.print &&
        <DailyDocketPrinted
          user={this.props.user}
          docket={this.props.hearingDay}
          hearings={this.props.hearings} />
      }

      {!this.props.print &&
        <DailyDocket
          user={this.props.user}
          dailyDocket={this.props.hearingDay}
          hearings={this.props.hearings}
          saveHearing={this.saveHearing}
          saveSuccessful={this.props.saveSuccessful}
          openModal={this.openModal}
          onClickRemoveHearingDay={this.props.onClickRemoveHearingDay}
          displayRemoveHearingDayModal={this.props.displayRemoveHearingDayModal}
          deleteHearingDay={this.deleteHearingDay}
          onDisplayLockModal={this.props.onDisplayLockModal}
          onCancelDisplayLockModal={this.props.onCancelDisplayLockModal}
          displayLockModal={this.props.displayLockModal}
          updateLockHearingDay={this.updateLockHearingDay}
          displayLockSuccessMessage={this.props.displayLockSuccessMessage}
          onErrorHearingDayLock={this.props.onErrorHearingDayLock} />
      }

      {this.state.modalOpen &&
        <HearingDayEditModal
          closeModal={this.closeModal}
          cancelModal={this.cancelModal} />
      }
    </LoadingDataDisplay>;

    return <div>{loadingDataDisplay}</div>;
  }
}

const mapStateToProps = (state) => ({
  hearingDay: state.dailyDocket.hearingDay,
  hearings: state.dailyDocket.hearings,
  saveSuccessful: state.dailyDocket.saveSuccessful,
  vlj: state.dailyDocket.vlj,
  coordinator: state.dailyDocket.coordinator,
  hearingRoom: state.dailyDocket.hearingRoom,
  notes: state.dailyDocket.notes,
  hearingDayModified: state.dailyDocket.hearingDayModified,
  displayRemoveHearingDayModal: state.dailyDocket.displayRemoveHearingDayModal,
  displayLockModal: state.dailyDocket.displayLockModal,
  displayLockSuccessMessage: state.dailyDocket.displayLockSuccessMessage,
  dailyDocketServerError: state.dailyDocket.dailyDocketServerError,
  onErrorHearingDayLock: state.dailyDocket.onErrorHearingDayLock
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onReceiveDailyDocket,
  onReceiveHearing,
  onReceiveSavedHearing,
  onResetSaveSuccessful,
  selectHearingRoom,
  selectVlj,
  selectHearingCoordinator,
  setNotes,
  onHearingDayModified,
  onClickRemoveHearingDay,
  onCancelRemoveHearingDay,
  onSuccessfulHearingDayDelete,
  onDisplayLockModal,
  onCancelDisplayLockModal,
  onUpdateLock,
  onResetLockSuccessMessage,
  handleDailyDocketServerError,
  onResetDailyDocketAfterError,
  handleLockHearingServerError,
  onResetLockHearingAfterError
}, dispatch);

DailyDocketContainer.propTypes = {
  user: PropTypes.object,
  hearingDay: PropTypes.object,
  hearings: PropTypes.object,
  saveSuccessful: PropTypes.object,
  vlj: PropTypes.string,
  coordinator: PropTypes.string,
  hearingRoom: PropTypes.string,
  notes: PropTypes.string,
  hearingDayModified: PropTypes.bool,
  displayRemoveHearingDayModal: PropTypes.bool,
  displayLockModal: PropTypes.bool,
  displayLockSuccessMessage: PropTypes.bool,
  dailyDocketServerError: PropTypes.bool,
  onErrorHearingDayLock: PropTypes.bool,
  print: PropTypes.bool
};

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(DailyDocketContainer));
