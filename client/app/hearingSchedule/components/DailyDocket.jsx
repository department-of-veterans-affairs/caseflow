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
import { getTime, getTimeInDifferentTimeZone } from '../../util/DateUtil';
import { DISPOSITION_OPTIONS } from '../../hearings/constants/constants';

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

const alertStyling = css({
  marginBottom: '30px'
});

export default class DailyDocket extends React.Component {

  componentDidUpdate = (prevProps) => {
    if (_.isNil(prevProps.saveSuccessful) && this.props.saveSuccessful) {

      return;
    }

    this.props.onResetSaveSuccessful();
  };

  componentWillUnmount = () => {
    this.props.onResetSaveSuccessful();
  };

  emptyFunction = () => {
    // This is a placeholder for when we add onChange functions to the page.
  };

  onHearingNotesUpdate = (hearingId) => (notes) => {
    this.props.onHearingNotesUpdate(hearingId, notes);
  };

  onHearingDispositionUpdate = (hearingId) => (disposition) => {
    this.props.onHearingDispositionUpdate(hearingId, disposition.value);
  };

  onHearingDateUpdate = (hearingId) => (date) => {
    this.props.onHearingDateUpdate(hearingId, date.value);
  };

  onHearingTimeUpdate = (hearingId) => (time) => {
    this.props.onHearingTimeUpdate(hearingId, time);
  };

  saveHearing = (hearing) => () => {
    this.props.saveHearing(hearing);
  };

  cancelHearingUpdate = (hearing) => () => {
    this.props.onCancelHearingUpdate(hearing);
  };

  previouslyScheduledHearings = () => {
    return _.filter(this.props.hearings, (hearing) => hearing.disposition === 'postponed');
  };

  dailyDocketHearings = () => {
    return _.filter(this.props.hearings, (hearing) => hearing.disposition !== 'postponed');
  };

  getAppellantInformation = (hearing) => {
    const appellantName = hearing.appellantMiFormatted || hearing.veteranMiFormatted;

    return <div><b>{appellantName} ({hearing.vbmsId})</b> <br />
      {hearing.appellantAddressLine1}<br />
      {hearing.appellantCity} {hearing.appellantState} {hearing.appellantZip}
    </div>;
  };

  getHearingTime = (hearing) => {
    if (hearing.requestType === 'CO') {
      return <div>{getTime(hearing.date)} <br />
        {hearing.regionalOfficeName}
      </div>;
    }

    return <div>{getTime(hearing.date)} /<br />
      {getTimeInDifferentTimeZone(hearing.date, hearing.regionalOfficeTimezone)} <br />
      {hearing.regionalOfficeName}
    </div>;

  }

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
      label: this.getHearingDate(hearingDayOption.hearingDate),
      value: this.getHearingDate(hearingDayOption.hearingDate)
    }));
  };

  getHearingLocationDropdown = (hearing) => {
    return <SearchableDropdown
      name="Hearing Location"
      options={this.getHearingLocationOptions(hearing)}
      value={hearing.readableLocation}
      onChange={this.emptyFunction}
      readOnly
    />;
  };

  getHearingTimeOptions = (hearing) => {
    if (hearing.requestType === 'CO') {
      return [
        {
          displayText: '9:00',
          value: '9:00 am ET'
        },
        {
          displayText: '1:00',
          value: '1:00 pm ET'
        }
      ];
    }

    return [
      {
        displayText: '8:30',
        value: '8:30 am ET'
      },
      {
        displayText: '12:30',
        value: '12:30 pm ET'
      }
    ];
  };

  getHearingDayDropdown = (hearing, readOnly) => {
    return <div><SearchableDropdown
      name="Hearing Day"
      options={this.getHearingDateOptions()}
      value={hearing.editedDate ? this.getHearingDate(hearing.editedDate) : this.getHearingDate(hearing.date)}
      onChange={this.onHearingDateUpdate(hearing.id)}
      readOnly={readOnly || hearing.editedDisposition !== 'postponed'}
    />
    <RadioField
      name={`hearingTime${hearing.id}`}
      options={this.getHearingTimeOptions(hearing)}
      value={hearing.editedTime ? hearing.editedTime : getTime(hearing.date)}
      onChange={this.onHearingTimeUpdate(hearing.id)}
      hideLabel
    />
    </div>;
  };

  getNotesField = (hearing) => {
    return <TextareaField
      name="Notes"
      onChange={this.onHearingNotesUpdate(hearing.id)}
      textAreaStyling={notesFieldStyling}
      value={_.isUndefined(hearing.editedNotes) ? hearing.notes : hearing.editedNotes || ''}
    />;
  };

  getSaveButton = (hearing) => {
    return hearing.edited ? <div>
      <Button
        linkStyling
        onClick={this.cancelHearingUpdate(hearing)}
      >
        Cancel
      </Button>
      <Button
        styling={buttonStyling}
        disabled={hearing.dateEdited && !hearing.dispositionEdited}
        onClick={this.saveHearing(hearing)}
      >
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
      },
      {
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

    return <AppSegment filledBackground>
      { this.props.saveSuccessful && <Alert
        type="success"
        styling={alertStyling}
        title={`You have successfully updated ${this.props.saveSuccessful.appellantMiFormatted ||
          this.props.saveSuccessful.veteranMiFormatted}'s hearing.`}
      /> }
      <div className="cf-push-left">
        <h1>Daily Docket ({moment(this.props.dailyDocket.hearingDate).format('ddd M/DD/YYYY')})</h1> <br />
        <div {...backLinkStyling}><Link to="/schedule">&lt; Back to schedule</Link></div>
      </div>
      <span className="cf-push-right">
        VLJ: {this.props.dailyDocket.judgeFirstName} {this.props.dailyDocket.judgeLastName} <br />
        Coordinator: {this.props.dailyDocket.bvaCoordinator} <br />
        Hearing type: {this.props.dailyDocket.hearingType}
      </span>
      <div {...noMarginStyling}>
        <Table
          columns={dailyDocketColumns}
          rowObjects={this.getDailyDocketRows(this.dailyDocketHearings(this.props.hearings), false)}
          summary="dailyDocket"
          bodyStyling={tableRowStyling}
        />
      </div>
      { !_.isEmpty(this.previouslyScheduledHearings(this.props.hearings)) && <div>
        <h1>Previously Scheduled</h1>
        <div {...noMarginStyling}>
          <Table
            columns={dailyDocketColumns}
            rowObjects={this.getDailyDocketRows(this.previouslyScheduledHearings(), true)}
            summary="dailyDocket"
            bodyStyling={tableRowStyling}
          />
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
  onHearingTimeUpdate: PropTypes.func
};
