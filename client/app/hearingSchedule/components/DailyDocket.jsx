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
      width: '20%' },
    '& > td:nth-child(5)': { backgroundColor: '#f1f1f1',
      width: '20%' },
    '& > td:nth-child(6)': { backgroundColor: '#f1f1f1',
      width: '20%' }
  },
  '& > tr:nth-child(even)': {
    '& > td:nth-child(1)': { width: '4%' },
    '& > td:nth-child(2)': { width: '19%' },
    '& > td:nth-child(3)': { width: '17%' },
    '& > td:nth-child(4)': { backgroundColor: '#f1f1f1',
      width: '40%' },
    '& > td:nth-child(5)': { backgroundColor: '#f1f1f1',
      width: '20%' }
  }
});

const notesFieldStyling = css({
  height: '50px'
});

const noMarginStyling = css({
  marginRight: '-40px',
  marginLeft: '-40px'
});

export default class DailyDocket extends React.Component {

  emptyFunction = () => {
    // This is a placeholder for when we add onChange functions to the page.
  };

  getAppellantInformation = (hearing) => {
    return <div><b>{hearing.appellantMiFormatted} ({hearing.vbmsId})</b> <br />
      {hearing.appellantAddressLine1}<br />
      {hearing.appellantCity} {hearing.appellantState} {hearing.appellantZip}
    </div>;
  };

  getHearingTime = (hearing) => {
    return <div>{getTime(hearing.date)} /<br />
      {getTimeInDifferentTimeZone(hearing.date, hearing.regionalOfficeTimezone)} <br />
      {hearing.regionalOfficeName}
    </div>;
  };

  getDispositionDropdown = (hearing) => {
    return <SearchableDropdown
      name="Disposition"
      options={DISPOSITION_OPTIONS}
      value={hearing.disposition}
      onChange={this.emptyFunction}
    />;
  };

  getHearingLocation = (hearing) => {
    if (hearing.requestType === 'CO') {
      return 'Washington DC';
    }

    return hearing.regionalOfficeName;
  };

  getHearingLocationOptions = (hearing) => {
    return [{ label: this.getHearingLocation(hearing),
      value: this.getHearingLocation(hearing) }];
  };

  getHearingDate = (hearing) => {
    return moment(hearing.date).format('MM/DD/YYYY');
  };

  getHearingDateOptions = (hearing) => {
    return [{ label: this.getHearingDate(hearing),
      value: this.getHearingDate(hearing) }];
  };

  getHearingLocationDropdown = (hearing) => {
    return <SearchableDropdown
      name="Hearing Location"
      options={this.getHearingLocationOptions(hearing)}
      value={this.getHearingLocation(hearing)}
      onChange={this.emptyFunction}
    />;
  };

  getHearingDayDropdown = (hearing) => {
    return <div><SearchableDropdown
      name="Hearing Day"
      options={this.getHearingDateOptions(hearing)}
      value={this.getHearingDate(hearing)}
      onChange={this.emptyFunction}
    />
    <RadioField
      name="Hearing Time"
      options={[
        {
          displayText: '8:30',
          value: '8:30'
        },
        {
          displayText: '1:30',
          value: '1:30'
        }
      ]}
      onChange={this.emptyFunction}
      hideLabel
    />
    </div>;
  };

  getNotesField = (hearing) => {
    return <TextareaField
      name="Notes"
      onChange={this.emptyFunction}
      textAreaStyling={notesFieldStyling}
      value={hearing.notes}
    />;
  };

  getDailyDocketRows = (hearings) => {
    let dailyDocketRows = [];

    _.forEach(hearings, (hearing) => {
      dailyDocketRows.push({
        number: '1.',
        appellantInformation: this.getAppellantInformation(hearing),
        hearingTime: this.getHearingTime(hearing),
        hearingLocation: this.getHearingLocationDropdown(hearing),
        hearingDay: this.getHearingDayDropdown(hearing),
        disposition: this.getDispositionDropdown(hearing)
      },
      {
        number: null,
        appellantInformation: <div>{hearing.representative} <br /> {hearing.representativeName}</div>,
        hearingTime: <div>{hearing.currentIssueCount} issues</div>,
        hearingLocation: this.getNotesField(hearing),
        hearingDay: null,
        disposition: null
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
        valueName: 'hearingLocation',
        span: (row) => row.hearingDay ? 1 : 2
      },
      {
        header: '',
        align: 'left',
        valueName: 'hearingDay',
        span: (row) => row.hearingDay ? 1 : 0
      },
      {
        header: '',
        align: 'left',
        valueName: 'disposition'
      }
    ];

    return <AppSegment filledBackground>
      <div className="cf-push-left">
        <h1>Daily Docket ({moment(this.props.dailyDocket.hearingDate).format('ddd M/DD/YYYY')})</h1> <br />
        <Link to="/schedule">&lt; Back to schedule</Link>
      </div>
      <span className="cf-push-right">
        VLJ: {this.props.dailyDocket.judgeFirstName} {this.props.dailyDocket.judgeLastName} <br />
        Hearing type: {this.props.dailyDocket.hearingType}
      </span>
      <div {...noMarginStyling}>
        <Table
          columns={dailyDocketColumns}
          rowObjects={this.getDailyDocketRows(this.props.dailyDocket.hearings)}
          summary="dailyDocket"
          bodyStyling={tableRowStyling}
        />
      </div>
    </AppSegment>;
  }
}

DailyDocket.propTypes = {
  vlj: PropTypes.string,
  coordinator: PropTypes.string,
  hearingType: PropTypes.string,
  hearingDate: PropTypes.string,
  hearings: PropTypes.object
};
