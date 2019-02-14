/* eslint-disable max-lines */

import React from 'react';
import PropTypes from 'prop-types';
import moment from 'moment';
import { css } from 'glamor';
import _ from 'lodash';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import Table from '../../components/Table';
import Checkbox from '../../components/Checkbox';
import RadioField from '../../components/RadioField';
import SearchableDropdown from '../../components/SearchableDropdown';
import TextareaField from '../../components/TextareaField';
import Button from '../../components/Button';
import Alert from '../../components/Alert';
import Modal from '../../components/Modal';
import StatusMessage from '../../components/StatusMessage';
import { DISPOSITION_OPTIONS, TIME_OPTIONS } from '../../hearings/constants/constants';
import { getTime, getTimeInDifferentTimeZone, getTimeWithoutTimeZone, formatDateStr } from '../../util/DateUtil';
import DocketTypeBadge from '../../components/DocketTypeBadge';
import { crossSymbolHtml, pencilSymbol, lockIcon } from '../../components/RenderFunctions';
import {
  RegionalOfficeDropdown,
  HearingDateDropdown,
  VeteranHearingLocationsDropdown
} from '../../components/DataDropdowns';

const tableRowStyling = css({
  '& > tr:nth-child(even) > td': { borderTop: 'none' },
  '& > tr:nth-child(odd) > td': { borderBottom: 'none' },
  '& > tr': { borderBottom: '1px solid #ddd' },
  '& > tr > td': {
    verticalAlign: 'top'
  },
  '& > tr:nth-child(odd)': {
    '& > td:nth-child(1)': { width: '4%' },
    '& > td:nth-child(2)': { width: '19%' },
    '& > td:nth-child(3)': { width: '17%' },
    '& > td:nth-child(4)': { backgroundColor: '#f1f1f1',
      width: '60%' }
  },
  '& > tr:nth-child(even)': {
    '& > td:nth-child(1)': { width: '4%' },
    '& > td:nth-child(2)': { width: '19%' },
    '& > td:nth-child(3)': { width: '17%' },
    '& > td:nth-child(4)': { backgroundColor: '#f1f1f1',
      width: '60%' }
  }
});

const notesFieldStyling = css({
  height: '50px'
});

const noMarginStyling = css({
  marginRight: '-40px',
  marginLeft: '-40px'
});

const backLinkStyling = css({
  marginTop: '-35px',
  marginBottom: '25px'
});

const editLinkStyling = css({
  marginLeft: '30px'
});

const alertStyling = css({
  marginBottom: '30px'
});

const topMarginStyling = css({
  marginTop: '170px'
});

const notesTitleStyling = css({
  marginTop: '15px'
});

const radioButtonStyling = css({ marginTop: '25px' });

const formStyling = css({
  '& .cf-form-radio-option:not(:last-child)': {
    display: 'inline-block',
    marginRight: '25px'
  },
  marginBottom: 0
});

export default class DailyDocket extends React.Component {

  onHearingNotesUpdate = (hearingId) => (notes) => this.props.onHearingNotesUpdate(hearingId, notes);

  onTranscriptRequestedUpdate = (hearingId) => (transcriptRequested) => {
    this.props.onTranscriptRequestedUpdate(hearingId, transcriptRequested);
  };

  onHearingDispositionUpdate = (hearingId) => (disposition) => {
    this.props.onHearingDispositionUpdate(hearingId, disposition.value);
  };

  onHearingDateUpdate = (hearingId) => (hearingDay) => this.props.onHearingDateUpdate(hearingId, hearingDay);

  onHearingTimeUpdate = (hearingId) => (time) => this.props.onHearingTimeUpdate(hearingId, time);

  onHearingLocationUpdate = (hearingId) => (location) => this.props.onHearingLocationUpdate(hearingId, location);

  onHearingRegionalOfficeUpdate = (hearingId) => (regionalOffice) =>
    this.props.onHearingRegionalOfficeUpdate(hearingId, regionalOffice);

  onInvalidForm = (hearingId) => (invalid) => this.props.onInvalidForm(hearingId, invalid);

  saveHearing = (hearing) => () => this.props.saveHearing(hearing);

  cancelHearingUpdate = (hearing) => () => this.props.onCancelHearingUpdate(hearing);

  previouslyScheduled = (hearing) => {
    return hearing.disposition === 'postponed' || hearing.disposition === 'cancelled';
  };

  previouslyScheduledHearings = () => {
    return _.filter(this.props.hearings, (hearing) => this.previouslyScheduled(hearing));
  };

  dailyDocketHearings = () => {
    return _.filter(this.props.hearings, (hearing) => !this.previouslyScheduled(hearing));
  };

   onHearingOptionalTime = (hearingId) => (optionalTime) => {
     this.props.onHearingOptionalTime(hearingId, optionalTime.value);
   }

  getAppellantName = (hearing) => {
    let { appellantFirstName, appellantLastName, veteranFirstName, veteranLastName } = hearing;

    if (appellantFirstName && appellantLastName) {
      return `${appellantFirstName} ${appellantLastName}`;
    }

    return `${veteranFirstName} ${veteranLastName}`;
  };

  getAppellantInformation = (hearing) => {
    const appellantName = this.getAppellantName(hearing);

    return <div><b>{appellantName}</b><br />
      <b><Link
        href={`/queue/appeals/${hearing.appealExternalId}`}
        name={hearing.veteranFileNumber} >
        {hearing.veteranFileNumber}
      </Link></b><br />
      <DocketTypeBadge name={hearing.docketName} number={hearing.docketNumber} />
      {hearing.docketNumber}
      <br /><br />
      {hearing.appellantAddressLine1}<br />
      {hearing.appellantCity} {hearing.appellantState} {hearing.appellantZip}
      <div>{hearing.representative} <br /> {hearing.representativeName}</div>
    </div>;
  };

  getHearingTime = (hearing) => {
    if (hearing.requestType === 'Central') {
      return <div>{getTime(hearing.scheduledFor)} <br />
        {hearing.regionalOfficeName}
      </div>;
    }

    return <div>{getTime(hearing.scheduledFor)} /<br />
      {getTimeInDifferentTimeZone(hearing.scheduledFor, hearing.regionalOfficeTimezone)} <br />
      {hearing.regionalOfficeName}
      <p>{hearing.currentIssueCount} issues</p>
    </div>;
  };

  getDispositionDropdown = (hearing, readOnly) => {
    return <SearchableDropdown
      name="Disposition"
      strongLabel
      options={DISPOSITION_OPTIONS}
      value={hearing.editedDisposition ? hearing.editedDisposition : hearing.disposition}
      onChange={(option) => {
        this.onHearingDispositionUpdate(hearing.id)(option);
        if (option.value === 'postponed') {
          this.onHearingDateUpdate(hearing.id)(null);
        }
      }}
      readOnly={readOnly || !_.isUndefined(hearing.editedDate)}
    />;
  };

  getRegionalOffice = () => {
    const { dailyDocket } = this.props;

    return dailyDocket.requestType === 'Central' ? 'C' : dailyDocket.regionalOfficeKey;
  }

  getRegionalOfficeDropdown = (hearing, readOnly) => {
    return <RegionalOfficeDropdown
      readOnly={readOnly || hearing.editedDisposition !== 'postponed'}
      onChange={this.onHearingRegionalOfficeUpdate(hearing.id)}
      value={hearing.editedRegionalOffice || this.getRegionalOffice()} />;
  };

  getHearingLocationDropdown = (hearing, readOnly) => {
    const currentRegionalOffice = hearing.editedRegionalOffice || hearing.regionalOfficeKey;
    let staticHearingLocations = hearing.veteranAvailableHearingLocations ?
      _.values(hearing.veteranAvailableHearingLocations) : [];

    // always static for now
    if (staticHearingLocations.length === 0 && hearing.location) {
      staticHearingLocations = [hearing.location];
    }

    return <VeteranHearingLocationsDropdown
      readOnly={readOnly}
      veteranFileNumber={hearing.veteranFileNumber}
      regionalOffice={currentRegionalOffice}
      staticHearingLocations={staticHearingLocations}
      dynamic={false}
      value={hearing.editedLocation || (hearing.location ? hearing.location.facilityId : null)}
      onChange={this.onHearingLocationUpdate(hearing.id)}
    />;
  };

  getHearingTimeOptions = (hearing, readOnly) => {
    if (hearing.readableRequestType === 'Central') {
      return [
        {
          displayText: '9:00',
          value: '9:00',
          disabled: readOnly
        },
        {
          displayText: '1:00',
          value: '13:00',
          disabled: readOnly
        },
        {
          displayText: 'Other',
          value: 'other',
          disabled: readOnly
        }
      ];
    }

    return [
      {
        displayText: '8:30',
        value: '8:30',
        disabled: readOnly
      },
      {
        displayText: '12:30',
        value: '12:30',
        disabled: readOnly
      },
      {
        displayText: 'Other',
        value: 'other',
        disabled: readOnly
      }
    ];
  };

  getHearingDayDropdown = (hearing, readOnly) => {
    const regionalOffice = this.getRegionalOffice();
    const currentRegionalOffice = hearing.editedRegionalOffice || regionalOffice;
    // if date is in the past, always add current date as an option
    const staticOptions = regionalOffice === currentRegionalOffice ?
      [{
        label: formatDateStr(hearing.scheduledFor),
        value: {
          scheduledFor: hearing.scheduledFor,
          hearingId: this.props.dailyDocket.id
        }
      }] : null;

    return <HearingDateDropdown
      name="HearingDay"
      label="Hearing Day"
      key={currentRegionalOffice}
      regionalOffice={currentRegionalOffice}
      errorMessage={hearing.invalid ? hearing.invalid.hearingDate : null}
      value={_.isUndefined(hearing.editedDate) ? hearing.scheduledFor : hearing.editedDate}
      readOnly={readOnly || hearing.editedDisposition !== 'postponed'}
      staticOptions={staticOptions}
      onChange={this.onHearingDateUpdate(hearing.id)} />;
  };

  getTimeRadioButtons = (hearing, readOnly) => {
    const timezone = hearing.requestType === 'Central' ? 'America/New_York' : hearing.regionalOfficeTimezone;

    return <div {...radioButtonStyling}>
      <span {...formStyling}>
        <RadioField
          label="Time"
          name={`hearingTime${hearing.id}`}
          options={this.getHearingTimeOptions(hearing, readOnly)}
          value={hearing.editedTime ? hearing.editedTime : getTimeWithoutTimeZone(hearing.scheduledFor, timezone)}
          onChange={this.onHearingTimeUpdate(hearing.id)}
          strongLabel />
      </span>
      {hearing.editedTime === 'other' && <SearchableDropdown
        name="optionalTime"
        placeholder="Select a time"
        options={TIME_OPTIONS}
        value={hearing.editedOptionalTime ? hearing.editedOptionalTime :
          getTimeWithoutTimeZone(hearing.scheduledFor, timezone)}
        onChange={this.onHearingOptionalTime(hearing.id)}
        hideLabel />}
    </div>
    ;
  };

  getHearingDetailsLink = (hearing) => {
    return <div>
      <b>Hearing Details</b> <br /><br />
      <Link href={`/hearings/${hearing.externalId}/details`}>
        Edit Hearing Details
        <span {...css({ position: 'absolute' })}>
          {pencilSymbol()}
        </span>
      </Link>
    </div>;
  };

  getTranscriptRequested = (hearing) => {
    return <div>
      <b>Copy Requested by Appellant/Rep</b>
      <Checkbox
        label="Transcript Requested"
        name={`${hearing.id}.transcriptRequested`}
        value={_.isUndefined(hearing.editedTranscriptRequested) ?
          hearing.transcriptRequested || false : hearing.editedTranscriptRequested}
        onChange={this.onTranscriptRequestedUpdate(hearing.id)}
      /></div>;
  };

  getNotesField = (hearing) => {
    return <TextareaField
      name="Notes"
      strongLabel
      onChange={this.onHearingNotesUpdate(hearing.id)}
      textAreaStyling={notesFieldStyling}
      value={_.isUndefined(hearing.editedNotes) ? hearing.notes || '' : hearing.editedNotes}
    />;
  };

  validateAndSaveHearing = (hearing) => {
    return () => {
      if (hearing.editedDisposition === 'postponed' &&
        (!hearing.editedDate ||
          formatDateStr(hearing.editedDate.scheduledFor) === formatDateStr(hearing.scheduledFor))) {
        return this.onInvalidForm(hearing.id)({ hearingDate: 'Please select a new hearing date.' });
      }

      this.saveHearing(hearing)();
      this.onInvalidForm(hearing.id)({
        hearingDate: null
      });
    };
  }

  getSaveButton = (hearing) => {
    return hearing.edited ? <div {...css({
      content: ' ',
      clear: 'both',
      display: 'block'
    })}>
      <Button
        styling={css({ float: 'left' })}
        linkStyling
        onClick={this.cancelHearingUpdate(hearing)}>
        Cancel
      </Button>
      <Button
        styling={css({ float: 'right' })}
        disabled={hearing.dateEdited && !hearing.dispositionEdited}
        onClick={this.validateAndSaveHearing(hearing)}>
        Save
      </Button>
    </div> : null;
  };

  getHearingActions = (hearing, readOnly) => {
    const twoCol = css({
      '& > div': {
        width: '50%',
        float: 'left',
        padding: '0px 15px 15px 15px'
      },
      '& > div > *:not(:first-child)': {
        marginTop: '25px'
      },
      '&::after': {
        clear: 'both',
        content: ' ',
        display: 'block'
      }
    });

    return <div {...twoCol}>
      <div>
        {this.getDispositionDropdown(hearing, readOnly)}
        {this.getTranscriptRequested(hearing)}
        {this.getHearingDetailsLink(hearing)}
        {this.getNotesField(hearing)}
      </div>
      <div>
        {this.getRegionalOfficeDropdown(hearing, readOnly)}
        {this.getHearingLocationDropdown(hearing, readOnly)}
        {this.getHearingDayDropdown(hearing, readOnly)}
        {this.getTimeRadioButtons(hearing, readOnly)}
        {this.getSaveButton(hearing)}
      </div>
    </div>;
  }

  getDailyDocketRows = (hearings, readOnly) => {
    return _.map(_.orderBy(hearings, (hearing) => hearing.scheduledFor, 'asc'), (hearing, index) => ({
      number: <b>{index + 1}.</b>,
      appellantInformation: this.getAppellantInformation(hearing),
      hearingTime: this.getHearingTime(hearing),
      actions: this.getHearingActions(hearing, readOnly)
    }));
  }

  getRemoveHearingDayMessage = () => {
    return 'Once the hearing day is removed, users will no longer be able to ' +
      `schedule Veterans for this ${this.props.dailyDocket.requestType} hearing day on ` +
      `${moment(this.props.dailyDocket.scheduledFor).format('ddd M/DD/YYYY')}.`;
  };

  getDisplayLockModalTitle = () => {
    return this.props.dailyDocket.lock ? 'Unlock Hearing Day' : 'Lock Hearing Day';
  };

  getDisplayLockModalMessage = () => {
    if (this.props.dailyDocket.lock) {
      return 'This hearing day is locked. Do you want to unlock the hearing day';
    }

    return 'Completing this action will not allow more Veterans to be scheduled for this day. You can still ' +
      'make changes to the existing slots.';
  };

  render() {
    const dailyDocketColumns = [
      {
        header: '',
        align: 'center',
        valueName: 'number'
      },
      {
        header: 'Appellant/Veteran ID/Representative',
        align: 'left',
        valueName: 'appellantInformation'
      },
      {
        header: 'Time/RO(s)',
        align: 'left',
        valueName: 'hearingTime'
      },
      {
        header: 'Actions',
        align: 'left',
        valueName: 'actions'
      }
    ];

    const dailyDocketRows = this.getDailyDocketRows(this.dailyDocketHearings(this.props.hearings), false);
    const cancelButton = <Button linkStyling onClick={this.props.onCancelRemoveHearingDay}>Go back</Button>;
    const confirmButton = <Button classNames={['usa-button-secondary']} onClick={this.props.deleteHearingDay}>
      Confirm
    </Button>;

    const cancelLockModalButton = <Button linkStyling onClick={this.props.onCancelDisplayLockModal}>Go back</Button>;
    const confirmLockModalButton = <Button
      classNames={['usa-button-secondary']}
      onClick={this.props.updateLockHearingDay(!this.props.dailyDocket.lock)}>
        Confirm
    </Button>;

    const lockSuccessMessageTitle = this.props.dailyDocket.lock ? 'You have successfully locked this Hearing ' +
      'Day' : 'You have successfully unlocked this Hearing Day';
    const lockSuccessMessage = this.props.dailyDocket.lock ? 'You cannot add more veterans to this hearing day, ' +
      'but you can edit existing entries' : 'You can now add more veterans to this hearing day';

    return <AppSegment filledBackground>
      {this.props.displayRemoveHearingDayModal && <div>
        <Modal
          title="Remove Hearing Day"
          closeHandler={this.props.onCancelRemoveHearingDay}
          confirmButton={confirmButton}
          cancelButton={cancelButton} >
          {this.getRemoveHearingDayMessage()}
        </Modal>
      </div>}
      {this.props.displayLockModal && <div>
        <Modal
          title={this.getDisplayLockModalTitle()}
          closeHandler={this.props.onCancelDisplayLockModal}
          confirmButton={confirmLockModalButton}
          cancelButton={cancelLockModalButton} >
          {this.getDisplayLockModalMessage()}
        </Modal>
      </div>}
      { this.props.saveSuccessful && <Alert
        type="success"
        styling={alertStyling}
        title={`You have successfully updated ${this.getAppellantName(this.props.saveSuccessful)}'s hearing.`}
      />
      }
      { this.props.displayLockSuccessMessage && <Alert
        type="success"
        styling={alertStyling}
        title={lockSuccessMessageTitle}
        message={lockSuccessMessage} /> }
      { this.props.dailyDocketServerError && <Alert
        type="error"
        styling={alertStyling}
        title={` Unable to delete Hearing Day
                ${moment(this.props.dailyDocket.scheduledFor).format('M/DD/YYYY')} in Caseflow.`}
        message="Please delete the hearing day through VACOLS" />}

      { this.props.onErrorHearingDayLock && <Alert
        type="error"
        styling={alertStyling}
        title={`VACOLS Hearing Day ${moment(this.props.dailyDocket.scheduledFor).format('M/DD/YYYY')}
           cannot be locked in Caseflow.`}
        message="VACOLS Hearing Day cannot be locked"
      />}

      <div className="cf-push-left">
        <h1>Daily Docket ({moment(this.props.dailyDocket.scheduledFor).format('ddd M/DD/YYYY')})</h1> <br />
        <div {...backLinkStyling}>
          <Link
            linkStyling to="/schedule" >&lt; Back to schedule</Link>&nbsp;&nbsp;
          <Button
            {...editLinkStyling}
            linkStyling
            onClick={this.props.openModal} >
            <span {...css({ position: 'absolute' })}>{pencilSymbol()}</span>
            <span {...css({ marginRight: '5px',
              marginLeft: '20px' })}>Edit Hearing Day</span>
          </Button>&nbsp;&nbsp;
          <Button
            linkStyling
            onClick={this.props.onDisplayLockModal} >
            <span {...css({ position: 'absolute',
              '& > svg > g > g': { fill: '#0071bc' } })}>{lockIcon()}</span>
            <span {...css({ marginRight: '5px',
              marginLeft: '16px' })}>
              {this.props.dailyDocket.lock ? 'Unlock Hearing Day' : 'Lock Hearing Day'}
            </span>
          </Button>&nbsp;&nbsp;
          { _.isEmpty(this.props.hearings) && this.props.userRoleBuild &&
          <Button
            linkStyling
            onClick={this.props.onClickRemoveHearingDay} >
            {crossSymbolHtml()}<span{...css({ marginLeft: '3px' })}>Remove Hearing Day</span>
          </Button>
          }
          {this.props.dailyDocket.notes &&
          <span {...notesTitleStyling}>
            <br /><strong>Notes: </strong>
            <br />{this.props.dailyDocket.notes}
          </span>
          }
        </div>
      </div>
      <span className="cf-push-right">
        VLJ: {this.props.dailyDocket.judgeFirstName} {this.props.dailyDocket.judgeLastName} <br />
        Coordinator: {this.props.dailyDocket.bvaPoc} <br />
        Hearing type: {this.props.dailyDocket.requestType} <br />
        Regional office: {this.props.dailyDocket.regionalOffice}<br />
        Room number: {this.props.dailyDocket.room}
      </span>
      <div {...noMarginStyling}>
        { !_.isEmpty(dailyDocketRows) && <Table
          columns={dailyDocketColumns}
          rowObjects={dailyDocketRows}
          summary="dailyDocket"
          bodyStyling={tableRowStyling}
          slowReRendersAreOk />}
      </div>
      { _.isEmpty(dailyDocketRows) && <div {...topMarginStyling}>
        <StatusMessage
          title= "No Veterans are scheduled for this hearing day."
          type="status" /></div>}
      { !_.isEmpty(this.previouslyScheduledHearings(this.props.hearings)) && <div>
        <h1>Previously Scheduled</h1>
        <div {...noMarginStyling}>
          <Table
            columns={dailyDocketColumns}
            rowObjects={this.getDailyDocketRows(this.previouslyScheduledHearings(), true)}
            summary="dailyDocket"
            bodyStyling={tableRowStyling}
            slowReRendersAreOk />
        </div>
      </div> }
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
  notes: PropTypes.string,
  onHearingOptionalTime: PropTypes.func
};
