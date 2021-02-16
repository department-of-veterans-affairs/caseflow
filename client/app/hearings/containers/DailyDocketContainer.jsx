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

  loadHearingDay = () => {
    const requestUrl = `/hearings/hearing_day/${this.props.match.params.hearingDayId}`;

    return ApiUtil.get(requestUrl).then((response) => {
      const resp = ApiUtil.convertToCamelCase(response.body);

      const hearings = _.keyBy(resp.hearingDay.hearings, 'externalId');
      const hearingDay = _.omit(resp.hearingDay, ['hearings']);

      this.props.onReceiveDailyDocket(hearingDay, hearings);
    });
  };

  formatHearingFormData = (hearingFormData) => {
    const { virtualHearing, location, ...rest } = hearingFormData;

    return ApiUtil.convertToSnakeCase(
      _.omitBy(
        {
          ..._.omit(rest, ['advanceOnDocketMotion']),
          hearing_location_attributes: location,
          virtual_hearing_attributes: virtualHearing || {}
        },
        _.isUndefined
      )
    );
  };

  formatAodMotionForm = (aodMotionForm, hearing) => {
    if (!aodMotionForm) {
      return {};
    }

    // always send full AOD data
    return ApiUtil.convertToSnakeCase(
      {
        ..._.omit(hearing.advanceOnDocketMotion, ['date', 'judgeName', 'userId']),
        ...aodMotionForm,
        person_id: hearing.claimantId || hearing.advanceOnDocketMotion.personId
      }
    );
  }

  saveHearing = (hearingId, hearingFormData) => {
    const hearing = this.props.hearings[hearingId];
    const data = {
      hearing: this.formatHearingFormData(hearingFormData),
      advance_on_docket_motion: this.formatAodMotionForm(hearingFormData.advanceOnDocketMotion, hearing)
    };

    return ApiUtil.patch(`/hearings/${hearingId}`, { data }).
      then((response) => {
        const hearingResp = ApiUtil.convertToCamelCase(response.body.data);

        this.props.onReceiveSavedHearing(hearingResp);

        return response;
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
          const editedHearingDay = ApiUtil.convertToCamelCase(response.body);

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
      createLoadPromise={this.loadHearingDay}
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
          onCancelRemoveHearingDay={this.props.onCancelRemoveHearingDay}
          onClickRemoveHearingDay={this.props.onClickRemoveHearingDay}
          displayRemoveHearingDayModal={this.props.displayRemoveHearingDayModal}
          deleteHearingDay={this.deleteHearingDay}
          onDisplayLockModal={this.props.onDisplayLockModal}
          onCancelDisplayLockModal={this.props.onCancelDisplayLockModal}
          displayLockModal={this.props.displayLockModal}
          updateLockHearingDay={this.updateLockHearingDay}
          displayLockSuccessMessage={this.props.displayLockSuccessMessage}
          dailyDocketServerError={this.props.dailyDocketServerError}
          history={this.props.history}
          onErrorHearingDayLock={this.props.onErrorHearingDayLock} />
      }

      {this.state.modalOpen &&
        <HearingDayEditModal
          closeModal={this.closeModal}
          cancelModal={this.cancelModal}
          requestType={this.props.hearingDay.requestType} />
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
  children: PropTypes.node,
  user: PropTypes.object,
  hearingDay: PropTypes.object,
  hearings: PropTypes.object,
  saveSuccessful: PropTypes.object,
  vlj: PropTypes.oneOfType([
    PropTypes.string,
    PropTypes.shape({
      value: PropTypes.string
    })
  ]),
  coordinator: PropTypes.oneOfType([
    PropTypes.string,
    PropTypes.shape({
      value: PropTypes.string
    })
  ]),
  hearingRoom: PropTypes.oneOfType([
    PropTypes.string,
    PropTypes.shape({
      value: PropTypes.string
    })
  ]),
  notes: PropTypes.string,
  hearingDayModified: PropTypes.bool,
  displayRemoveHearingDayModal: PropTypes.bool,
  displayLockModal: PropTypes.bool,
  displayLockSuccessMessage: PropTypes.bool,
  dailyDocketServerError: PropTypes.bool,
  history: PropTypes.shape({
    push: PropTypes.func
  }),
  match: PropTypes.shape({
    params: PropTypes.shape({
      hearingDayId: PropTypes.string
    })
  }),
  handleDailyDocketServerError: PropTypes.func,
  handleLockHearingServerError: PropTypes.func,
  onDisplayLockModal: PropTypes.func,
  onCancelDisplayLockModal: PropTypes.func,
  onCancelRemoveHearingDay: PropTypes.func,
  onClickRemoveHearingDay: PropTypes.func,
  onErrorHearingDayLock: PropTypes.func,
  onSuccessfulHearingDayDelete: PropTypes.func,
  onReceiveDailyDocket: PropTypes.func,
  onReceiveSavedHearing: PropTypes.func,
  onResetSaveSuccessful: PropTypes.func,
  onResetLockHearingAfterError: PropTypes.func,
  onResetLockSuccessMessage: PropTypes.func,
  onResetDailyDocketAfterError: PropTypes.func,
  onUpdateLock: PropTypes.func,
  print: PropTypes.bool
};

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(DailyDocketContainer));
