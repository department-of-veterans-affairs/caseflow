import React from 'react';
import PropTypes from 'prop-types';
import moment from 'moment';
import { css } from 'glamor';
import _ from 'lodash';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Alert from '../../../components/Alert';
import {
  LockModal,
  RemoveHearingModal,
  DispositionModal,
} from './DailyDocketModals';
import Button from '../../../components/Button';
import StatusMessage from '../../../components/StatusMessage';
import DailyDocketRows from './DailyDocketRows';
import DailyDocketEditLinks from './DailyDocketEditLinks';
import { isPreviouslyScheduledHearing } from '../../utils';
import { navigateToPrintPage } from '../../../util/PrintUtil';
import { encodeQueryParams } from '../../../util/QueryParamsUtil';
import COPY from '../../../../COPY';
import UserAlerts from '../../../components/UserAlerts';
import HEARING_DISPOSITION_TYPES from '../../../../constants/HEARING_DISPOSITION_TYPES';
import { ScheduledInErrorModal } from '../ScheduledInErrorModal';

const alertStyling = css({
  marginBottom: '30px',
});

const Alerts = ({
  displayLockSuccessMessage,
  onErrorHearingDayLock,
  dailyDocket,
  dailyDocketServerError,
}) => (
  <React.Fragment>
    <UserAlerts />
    {displayLockSuccessMessage && (
      <Alert
        type="success"
        styling={alertStyling}
        title={
          dailyDocket.lock ?
            'You have successfully locked this Hearing Day' :
            'You have successfully unlocked this Hearing Day'
        }
        message={
          dailyDocket.lock ?
            'You cannot add more veterans to this hearing day, but you can edit existing entries' :
            'You can now add more veterans to this hearing day'
        }
      />
    )}

    {dailyDocketServerError && (
      <Alert
        type="error"
        styling={alertStyling}
        title=" This save was unsuccessful."
        message="Please refresh the page and try again."
      />
    )}

    {onErrorHearingDayLock && (
      <Alert
        type="error"
        styling={alertStyling}
        title={`VACOLS Hearing Day ${moment(dailyDocket.scheduledFor).format(
          'M/DD/YYYY'
        )}
           cannot be locked in Caseflow.`}
        message="VACOLS Hearing Day cannot be locked"
      />
    )}
  </React.Fragment>
);

Alerts.propTypes = {
  dailyDocket: PropTypes.shape({
    lock: PropTypes.bool,
    scheduledFor: PropTypes.string,
  }),
  dailyDocketServerError: PropTypes.bool,
  displayLockSuccessMessage: PropTypes.bool,
  onErrorHearingDayLock: PropTypes.bool,
  saveSuccessful: PropTypes.object,
};

export default class DailyDocket extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      editedDispositionModalProps: null,
      scheduledInErrorModalProps: null,
    };
  }

  previouslyScheduledHearings = () => {
    return _.filter(this.props.hearings, isPreviouslyScheduledHearing);
  };

  dailyDocketHearings = () => {
    const hearings = _.filter(
      this.props.hearings,
      _.negate(isPreviouslyScheduledHearing)
    ).filter(
      (hearing) =>
        hearing.disposition !== HEARING_DISPOSITION_TYPES.scheduled_in_error
    );

    return hearings;
  };

  getRegionalOffice = () => {
    const { dailyDocket } = this.props;

    // for Central hearing days, return 'C'
    // Otherwise assume it's a video hearing day and return RO key
    return dailyDocket.requestType === 'C' ? 'C' : dailyDocket.regionalOfficeKey;
  };

  openDispositionModal = ({
    update,
    hearing,
    fromDisposition,
    toDisposition,
    onConfirm,
    onCancel,
  }) => {
    // Wrap the cancel function to close the modal and reset the disposition
    const cancelHandler = () => {
      onCancel();
      this.closeDispositionModal();
    };

    if (toDisposition === HEARING_DISPOSITION_TYPES.scheduled_in_error) {
      this.setState({
        scheduledInErrorModalProps: {
          update,
          hearing,
          cancelHandler: this.closeDispositionModal,
          saveHearing: this.props.saveHearing,
          disposition: toDisposition,
        },
      });
    } else {
      this.setState({
        editedDispositionModalProps: {
          hearing,
          fromDisposition,
          toDisposition,
          onCancel: cancelHandler,
          onConfirm: () => {
            onConfirm(toDisposition);
            this.closeDispositionModal();
          },
        },
      });
    }
  };

  closeDispositionModal = () => {
    this.setState({
      editedDispositionModalProps: null,
      scheduledInErrorModalProps: null,
    });
  };

  navigateToPrintAllPage = () => {
    const hearingIds = this.dailyDocketHearings().map((hearing) => hearing.externalId);
    const queryString = encodeQueryParams({
      hearing_ids: hearingIds.join(','),
      keep_open: true,
    });

    navigateToPrintPage(`/hearings/worksheet/print${queryString}`);
  };

  render() {
    const regionalOffice = this.getRegionalOffice();
    const docketHearings = this.dailyDocketHearings();
    const prevHearings = this.previouslyScheduledHearings();

    const hasDocketHearings = !_.isEmpty(docketHearings);
    const hasPrevHearings = !_.isEmpty(prevHearings);

    const {
      dailyDocket,
      onCancelRemoveHearingDay,
      onClickRemoveHearingDay,
      displayRemoveHearingDayModal,
      displayLockModal,
      openModal,
      deleteHearingDay,
      updateLockHearingDay,
      onCancelDisplayLockModal,
      user,
      history,
    } = this.props;

    const { editedDispositionModalProps, scheduledInErrorModalProps } = this.state;

    return (
      <AppSegment filledBackground>
        {editedDispositionModalProps && (
          <DispositionModal {...this.state.editedDispositionModalProps} />
        )}
        {scheduledInErrorModalProps && (
          <ScheduledInErrorModal
            {...this.state.scheduledInErrorModalProps}
            history={history}
            hearing={
              this.props.hearings[
                this.state.scheduledInErrorModalProps.hearing.externalId
              ]
            }
          />
        )}

        {displayRemoveHearingDayModal && (
          <RemoveHearingModal
            dailyDocket={dailyDocket}
            onCancelRemoveHearingDay={onCancelRemoveHearingDay}
            onClickRemoveHearingDay={onClickRemoveHearingDay}
            deleteHearingDay={deleteHearingDay}
          />
        )}

        {displayLockModal && (
          <LockModal
            dailyDocket={dailyDocket}
            updateLockHearingDay={updateLockHearingDay}
            onCancelDisplayLockModal={onCancelDisplayLockModal}
          />
        )}

        <Alerts
          dailyDocket={dailyDocket}
          saveSuccessful={this.props.saveSuccessful}
          displayLockSuccessMessage={this.props.displayLockSuccessMessage}
          dailyDocketServerError={this.props.dailyDocketServerError}
          onErrorHearingDayLock={this.props.onErrorHearingDayLock}
        />

        <div className="cf-app-segment">
          <div className="cf-push-left">
            <DailyDocketEditLinks
              dailyDocket={dailyDocket}
              hearings={docketHearings.concat(prevHearings)}
              user={user}
              openModal={openModal}
              onDisplayLockModal={this.props.onDisplayLockModal}
              onClickRemoveHearingDay={this.props.onClickRemoveHearingDay}
            />
          </div>
          <div className="cf-push-right">
            VLJ: {dailyDocket.judgeFirstName} {dailyDocket.judgeLastName} <br />
            Coordinator: {dailyDocket.bvaPoc} <br />
            Hearing type: {dailyDocket.readableRequestType} <br />
            Regional office: {dailyDocket.regionalOffice}
            <br />
            Room number: {dailyDocket.room}
          </div>
        </div>

        <div className="cf-app-segment">
          <div className="cf-push-left">
            <Button onClick={() => navigateToPrintPage()}>
              Download & Print Page
            </Button>
          </div>
          <div className="cf-push-right">
            {user.userHasHearingPrepRole && (
              <Button
                classNames={['usa-button-secondary']}
                onClick={this.navigateToPrintAllPage}
                disabled={_.isEmpty(docketHearings)}
              >
                Print all Hearing Worksheets
              </Button>
            )}
          </div>
        </div>

        <DailyDocketRows
          hearings={this.props.hearings}
          hidePreviouslyScheduled
          readOnly={
            user.userCanViewHearingSchedule || user.userCanVsoHearingSchedule
          }
          saveHearing={this.props.saveHearing}
          openDispositionModal={this.openDispositionModal}
          regionalOffice={regionalOffice}
          user={user}
        />

        {!hasDocketHearings && (
          <div {...css({ marginTop: '75px' })}>
            <StatusMessage
              title={
                user.userHasHearingPrepRole ?
                  COPY.HEARING_SCHEDULE_DOCKET_JUDGE_WITH_NO_HEARINGS :
                  COPY.HEARING_SCHEDULE_DOCKET_NO_VETERANS
              }
              type="status"
            />
          </div>
        )}

        {hasPrevHearings && (
          <div {...css({ marginTop: '75px' })}>
            <h1>Previously Scheduled</h1>
            <DailyDocketRows
              hidePreviouslyScheduled={false}
              hearings={prevHearings}
              regionalOffice={regionalOffice}
              user={user}
              readOnly
            />
          </div>
        )}
      </AppSegment>
    );
  }
}

DailyDocket.propTypes = {
  user: PropTypes.object.isRequired,
  dailyDocket: PropTypes.object,
  hearings: PropTypes.object,
  saveHearing: PropTypes.func.isRequired,
  saveSuccessful: PropTypes.object,
  openModal: PropTypes.func.isRequired,
  onCancelRemoveHearingDay: PropTypes.func,
  onClickRemoveHearingDay: PropTypes.func.isRequired,
  displayRemoveHearingDayModal: PropTypes.bool,
  deleteHearingDay: PropTypes.func.isRequired,
  onDisplayLockModal: PropTypes.func.isRequired,
  onCancelDisplayLockModal: PropTypes.func.isRequired,
  displayLockModal: PropTypes.bool,
  updateLockHearingDay: PropTypes.func.isRequired,
  displayLockSuccessMessage: PropTypes.bool,
  dailyDocketServerError: PropTypes.bool,
  onErrorHearingDayLock: PropTypes.bool,
  history: PropTypes.shape({
    push: PropTypes.func,
  }),
};
