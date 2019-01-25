/* eslint-disable max-lines */

import React from 'react';
import PropTypes from 'prop-types';
import moment from 'moment';
import { css } from 'glamor';
import _ from 'lodash';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import Table from '../../components/Table';
import RadioField from '../../components/RadioField';
import SearchableDropdown from '../../components/SearchableDropdown';
import TextareaField from '../../components/TextareaField';
import Button from '../../components/Button';
import Alert from '../../components/Alert';
import Modal from '../../components/Modal';
import StatusMessage from '../../components/StatusMessage';
import { getTime, getTimeInDifferentTimeZone, getTimeWithoutTimeZone } from '../../util/DateUtil';
import { DISPOSITION_OPTIONS, TIME_OPTIONS } from '../../hearings/constants/constants';
import DocketTypeBadge from '../../components/DocketTypeBadge';
import { crossSymbolHtml, pencilSymbol } from '../../components/RenderFunctions';

const tableRowStyling = css({
  '& > tr:nth-child(even) > td': { borderTop: 'none' },
  '& > tr:nth-child(odd) > td': { borderBottom: 'none' },
  '& > tr > td': {
    verticalAlign: 'top'
  },
  '& > tr:nth-child(odd)': {
    '& > td:nth-child(1)': { width: '4%' },
    '& > td:nth-child(2)': { width: '19%' },
    '& > td:nth-child(3)': { width: '17%' },
    '& > td:nth-child(4)': { backgroundColor: '#f1f1f1',
      width: '18%' },
    '& > td:nth-child(5)': { backgroundColor: '#f1f1f1',
      width: '20%' },
    '& > td:nth-child(6)': { backgroundColor: '#f1f1f1',
      width: '22%' }
  },
  '& > tr:nth-child(even)': {
    '& > td:nth-child(1)': { width: '4%' },
    '& > td:nth-child(2)': { width: '19%' },
    '& > td:nth-child(3)': { width: '17%' },
    '& > td:nth-child(4)': { backgroundColor: '#f1f1f1',
      width: '38%' },
    '& > td:nth-child(5)': { backgroundColor: '#f1f1f1',
      width: '22%' }
  }
});

const notesFieldStyling = css({
  height: '50px'
});

const noMarginStyling = css({
  marginRight: '-40px',
  marginLeft: '-40px'
});

const buttonStyling = css({
  marginTop: '35px'
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

export default class DailyDocket extends React.Component {

  onHearingNotesUpdate = (hearingId) => (notes) => this.props.onHearingNotesUpdate(hearingId, notes);

  onHearingDispositionUpdate = (hearingId) => (disposition) => {
    this.props.onHearingDispositionUpdate(hearingId, disposition.value);
  };

  onHearingDateUpdate = (hearingId) => (date) => this.props.onHearingDateUpdate(hearingId, date.value);

  onHearingTimeUpdate = (hearingId) => (time) => this.props.onHearingTimeUpdate(hearingId, time);

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

   onHearingOptionalTime= (value) => {
     this.props.onHearingOptionalTime(value);
   };

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
      <br />
      {hearing.appellantAddressLine1}<br />
      {hearing.appellantCity} {hearing.appellantState} {hearing.appellantZip}
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
    </div>;
  };

  getDispositionDropdown = (hearing, readOnly) => {
    return <SearchableDropdown
      name="Disposition"
      options={DISPOSITION_OPTIONS}
      value={hearing.editedDisposition ? hearing.editedDisposition : hearing.disposition}
      onChange={this.onHearingDispositionUpdate(hearing.id)}
      readOnly={readOnly || !_.isUndefined(hearing.editedDate)}
    />;
  };

  getHearingLocationOptions = (hearing) => {
    return [{ label: hearing.readableLocation,
      value: hearing.readableLocation }];
  };

  getHearingDate = (date) => {
    return moment(date).format('MM/DD/YYYY');
  };

  getHearingDateOptions = () => {
    return _.map(this.props.hearingDayOptions, (hearingDayOption) => ({
      label: this.getHearingDate(hearingDayOption.scheduledFor),
      value: hearingDayOption.id
    }));
  };

 getHearingDateOptions = (hearing) => {
   const hearings = [{ label: this.getHearingDate(hearing.scheduledFor),
     value: hearing.id }];

   const hearingDayoptions = _.map(this.props.hearingDayOptions, (hearingDayOption) => ({
     label: this.getHearingDate(hearingDayOption.scheduledFor),
     value: hearingDayOption.id
   }));

   if (this.props.hearingDayOptions) {
     return hearings.concat(hearingDayoptions);
   }
 };

  getHearingLocationDropdown = (hearing) => {
    return <SearchableDropdown
      name="Hearing Location"
      options={this.getHearingLocationOptions(hearing)}
      value={hearing.readableLocation}
      readOnly
    />;
  };

  getHearingTimeOptions = (hearing, readOnly) => {
    if (hearing.requestType === 'Central') {
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
    const timezone = hearing.requestType === 'Central' ? 'America/New_York' : hearing.regionalOfficeTimezone;

    return <div><SearchableDropdown
      name="HearingDay"
      label="Hearing Day"
      options={this.getHearingDateOptions(hearing)}
      value={hearing.editedDate ? hearing.editedDate : hearing.id}
      onChange={this.onHearingDateUpdate(hearing.id)}
      readOnly={readOnly || hearing.editedDisposition !== 'postponed'} />
    <div {...radioButtonStyling}>
      <RadioField
        name= "time"
        label= "Time"
        options={this.getHearingTimeOptions(hearing, readOnly)}
        value={hearing.editedTime ? hearing.editedTime : getTimeWithoutTimeZone(hearing.scheduledFor, timezone)}
        onChange={this.onHearingTimeUpdate(hearing.id)}
        strongLabel />
      {hearing.editedTime === 'other' && <SearchableDropdown
        name="optionalTime"
        placeholder="Select a time"
        options={TIME_OPTIONS}
        value={hearing.selectedOptionalTime ? hearing.selectedOptionalTime || '' : hearing.editedTime}
        onChange={this.onHearingOptionalTime(hearing.id)}
        hideLabel />}</div>

    </div>;
  };

  getNotesField = (hearing) => {
    return <TextareaField
      name="Notes"
      onChange={this.onHearingNotesUpdate(hearing.id)}
      textAreaStyling={notesFieldStyling}
      value={_.isUndefined(hearing.editedNotes) ? hearing.notes || '' : hearing.editedNotes}
    />;
  };

  getSaveButton = (hearing) => {
    return hearing.edited ? <div>
      <Button
        linkStyling
        onClick={this.cancelHearingUpdate(hearing)}>
        Cancel
      </Button>
      <Button
        styling={buttonStyling}
        disabled={hearing.dateEdited && !hearing.dispositionEdited}
        onClick={this.saveHearing(hearing)}>
        Save
      </Button>
    </div> : null;
  };

  getDailyDocketRows = (hearings, readOnly) => {
    let dailyDocketRows = [];
    let count = 0;

    _.forEach(hearings, (hearing) => {
      count += 1;
      dailyDocketRows.push({
        number: <b>{count}.</b>,
        appellantInformation: this.getAppellantInformation(hearing),
        hearingTime: this.getHearingTime(hearing),
        disposition: this.getDispositionDropdown(hearing, readOnly),
        hearingLocation: this.getHearingLocationDropdown(hearing),
        hearingDay: this.getHearingDayDropdown(hearing, readOnly)
      }, {
        number: null,
        appellantInformation: <div>{hearing.representative} <br /> {hearing.representativeName}</div>,
        hearingTime: <div>{hearing.currentIssueCount} issues</div>,
        disposition: this.getNotesField(hearing),
        hearingLocation: null,
        hearingDay: this.getSaveButton(hearing)
      });
    });

    return dailyDocketRows;
  };

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
        valueName: 'disposition',
        span: (row) => row.hearingLocation ? 1 : 2
      },
      {
        header: '',
        align: 'left',
        valueName: 'hearingLocation',
        span: (row) => row.hearingLocation ? 1 : 0
      },
      {
        header: '',
        align: 'left',
        valueName: 'hearingDay'
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
            <span {...css({ marginRight: '5px' })}>
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
          {this.props.notes &&
          <span {...notesTitleStyling}>
            <br /><strong>Notes: </strong>
            <br />{this.props.notes}
          </span>
          }
        </div>
      </div>
      <span className="cf-push-right">
        VLJ: {this.props.dailyDocket.judgeFirstName} {this.props.dailyDocket.judgeLastName} <br />
        Coordinator: {this.props.dailyDocket.bvaPoc} <br />
        Hearing type: {this.props.dailyDocket.requestType} <br />
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
  openModal: PropTypes.func,
  deleteHearingDay: PropTypes.func,
  notes: PropTypes.string,
  onHearingOptionalTime: PropTypes.func
};
