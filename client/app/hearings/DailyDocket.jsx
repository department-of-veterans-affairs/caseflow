import React from 'react';
import PropTypes from 'prop-types';
import moment from 'moment';
import { Link } from 'react-router-dom';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import { CATEGORIES, ACTIONS } from './analytics';
import { orderTheDocket } from './util/index';
import Table from '../components/Table';
import SearchableDropdown from '../components/SearchableDropdown';
import { getTime, getTimeInDifferentTimeZone, getDate } from '../util/DateUtil';
import {
  setNotes, setDisposition, setHoldOpen, setAod, setTranscriptRequested, setHearingViewed,
  setHearingPrepped
} from './actions/Dockets';
import { css } from 'glamor';
import _ from 'lodash';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { DISPOSITION_OPTIONS } from './constants/constants';
import Checkbox from '../components/Checkbox';
import ViewableItemLink from '../components/ViewableItemLink';
import Textarea from 'react-textarea-autosize';

const tableRowStyling = css({
  '& > tr:nth-child(even) > td': { borderTop: 'none' },
  '& > tr:nth-child(odd) > td': { borderBottom: 'none' },
  '& > tr > td': {
    verticalAlign: 'top'
  },
  '& > tr:nth-child(odd)': {
    '& > td:nth-child(1)': { width: '1%' },
    '& > td:nth-child(2)': { width: '2%',
      '> .cf-form-checkboxes': { marginTop: '0' } },
    '& > td:nth-child(3)': { width: '10%' },
    '& > td:nth-child(4)': { width: '18%' },
    '& > td:nth-child(5)': { width: '15%' },
    '& > td:nth-child(6)': { backgroundColor: '#f1f1f1',
      width: '15%' },
    '& > td:nth-child(7)': { backgroundColor: '#f1f1f1',
      width: '15%' },
    '& > td:nth-child(8)': { backgroundColor: '#f1f1f1',
      width: '15%' }
  },
  '& > tr:nth-child(even)': {
    '& > td:nth-child(1)': { width: '4%' },
    '& > td:nth-child(2)': { width: '2%' },
    '& > td:nth-child(4)': { width: '20%',
      '& label': {
        position: 'absolute',
        display: 'inline-block'
      },
      '& div': { paddingLeft: '5rem' },
      '& textarea': {
        minHeight: '4em',
        resize: 'vertical' } },
    '& > td:nth-child(5)': { backgroundColor: '#f1f1f1',
      width: '15%' },
    '& > td:nth-child(6)': { backgroundColor: '#f1f1f1',
      width: '15%' },
    '& > td:nth-child(7)': { backgroundColor: '#f1f1f1',
      width: '15%' },
    '& > td:nth-child(8)': { backgroundColor: '#f1f1f1',
      width: '15%' }
  }
});

const noMarginStyling = css({
  marginRight: '-40px',
  marginLeft: '-40px'
});

const preppedCheckboxStyling = css({
  float: 'right'
});

const issueCountStyling = css({
  display: 'block',
  paddingTop: '5px',
  paddingBottom: '5px'
});

const holdOption = (days, hearingDate) => ({
  value: days,
  label: `${days} days - ${moment(hearingDate).add(days, 'days').
    format('MM/DD')}`
});

const holdOptions = (hearingDate) => [
  holdOption(0, hearingDate),
  holdOption(30, hearingDate),
  holdOption(60, hearingDate),
  holdOption(90, hearingDate)];

const aodOptions = [{ value: 'granted',
  label: 'Granted' },
{ value: 'filed',
  label: 'Filed' },
{ value: 'none',
  label: 'None' }];

const selectedValue = (selected) => selected ? selected.value : null;

export class DailyDocket extends React.PureComponent {
  onclickBackToHearingDays = () => {
    window.analyticsEvent(CATEGORIES.DAILY_DOCKET_PAGE, ACTIONS.GO_BACK_TO_HEARING_DAYS);
  }

  setDisposition = (hearingId, hearingDate) => (selected) => {
    this.props.setDisposition(hearingId, selectedValue(selected), hearingDate);
  }

  setHoldOpen = (hearingId, hearingDate) => (selected) => {
    this.props.setHoldOpen(hearingId, selectedValue(selected), hearingDate);
  }

  setAod = (hearingId, hearingDate) => (selected) => {
    this.props.setAod(hearingId, selectedValue(selected), hearingDate);
  }

  setTranscriptRequested = (hearingId, hearingDate) => (value) => {
    this.props.setTranscriptRequested(hearingId, value, hearingDate);
  }

  setNotes = (hearingId, hearingDate) => (event) => {
    this.props.setNotes(hearingId, event.target.value, hearingDate);
  }

  setHearingViewed = (hearingId) => () => this.props.setHearingViewed(hearingId);

  preppedOnChange = (hearingId, hearingDate) => (value) => this.props.setHearingPrepped({
    hearingId,
    prepped: value,
    date: hearingDate,
    setEdited: true
  });

 getAppellantInformation = (hearing) => {
   let appellantDisplay;

   if (_.isEmpty(hearing.appellant_mi_formatted) ||
     hearing.appellant_mi_formatted === hearing.veteran_mi_formatted) {
     appellantDisplay = <div><b>{hearing.veteran_mi_formatted}</b><br />
       <ViewableItemLink
         boldCondition={!hearing.viewed_by_current_user}
         onOpen={this.setHearingViewed(hearing.id)}
         linkProps={{
           to: `/hearings/${hearing.external_id}/worksheet`,
           target: '_blank'
         }}>
         {hearing.vbms_id}
       </ViewableItemLink>
       <span {...issueCountStyling}>
         {hearing.current_issue_count} {hearing.current_issue_count === 1 ? 'Issue' : 'Issues' }
       </span>
     </div>;
   } else {
     appellantDisplay = <div>
       <span><b>{hearing.appellant_mi_formatted}</b><br />
         {hearing.veteran_mi_formatted} (Veteran)</span><br />
       <ViewableItemLink
         boldCondition={!hearing.viewed_by_current_user}
         onOpen={this.setHearingViewed(hearing.id)}
         linkProps={{
           to: `/hearings/${hearing.external_id}/worksheet`,
           target: '_blank'
         }}>
         {hearing.vbms_id}
       </ViewableItemLink>
       <span {...issueCountStyling}>
         {hearing.current_issue_count} {hearing.current_issue_count === 1 ? 'Issue' : 'Issues' }
       </span>
     </div>;
   }

   return appellantDisplay;
 }

getRoTime = (hearing) => {
  if (hearing.request_type === 'Central') {
    return <div>{getTime(hearing.scheduled_for)} <br />
      {hearing.regional_office_name}
    </div>;
  }

  return <div>{getTime(hearing.scheduled_for)} /<br />
    {getTimeInDifferentTimeZone(hearing.scheduled_for, hearing.regional_office_timezone)} <br />
    <span>{hearing.regional_office_name}</span>
  </div>;
};

getPrepCheckBox = (hearing) => {
  return <Checkbox
    id={`${hearing.id}-prep`}
    onChange={this.preppedOnChange(hearing.id, getDate(hearing.scheduled_for))}
    key={`${hearing.id}`}
    value={hearing.prepped || false}
    name={`${hearing.id}-prep`}
    hideLabel
    {...preppedCheckboxStyling}
  />;
};

getTranscriptRequested = (hearing) => {
  return <Checkbox
    label="Transcript Requested"
    name={`${hearing.id}.transcript_requested`}
    value={hearing.transcript_requested || false}
    onChange={this.setTranscriptRequested(hearing.id, getDate(hearing.scheduled_for))}
  />;
};

getDispositionDropdown = (hearing) => {
  return <SearchableDropdown
    label="Disposition"
    name={`${hearing.id}-disposition`}
    options={DISPOSITION_OPTIONS}
    onChange={this.setDisposition(hearing.id, getDate(hearing.scheduled_for))}
    value={hearing.disposition}
    searchable={false}
  />;
};

getHoldOpenDropdown = (hearing) => {
  return <SearchableDropdown
    label="Hold Open"
    name={`${hearing.id}-hold_open`}
    options={holdOptions(getDate(hearing.scheduled_for))}
    onChange={this.setHoldOpen(hearing.id, getDate(hearing.scheduled_for))}
    value={hearing.hold_open}
    searchable={false}
  />;
};

getAodDropdown = (hearing) => {
  return <SearchableDropdown
    label="AOD"
    name={`${hearing.id}-aod`}
    options={aodOptions}
    onChange={this.setAod(hearing.id, getDate(hearing.scheduled_for))}
    value={hearing.aod}
    searchable={false}
  />;
}

 getNotesField = (hearing) => {
   return <span>
     <label htmlFor={`${hearing.id}.notes`} aria-label="notes">Notes</label>
     <div>
       <Textarea
         id={`${hearing.id}.notes`}
         value={hearing.notes || ''}
         name="Notes"
         onChange={this.setNotes(hearing.id, getDate(hearing.scheduled_for))}
       />
     </div>
   </span>;
 };

  getDailyDocketRows = (hearing) => {
    let dailyDocketRows = [];
    let count = 0;

    _.forEach(hearing, (hearings) => {
      count += 1;
      dailyDocketRows.push({
        number: <b>{count}.</b>,
        prep: this.getPrepCheckBox(hearings),
        hearingTime: this.getRoTime(hearings),
        appellantInformation: this.getAppellantInformation(hearings),
        representative: <span>{hearings.representative}<br />{hearings.representative_name}</span>,
        disposition: this.getDispositionDropdown(hearings),
        holdOpen: this.getHoldOpenDropdown(hearings),
        aod: this.getAodDropdown(hearings)
      },
      {
        number: null,
        prep: null,
        hearingTime: null,
        appellantInformation: this.getNotesField(hearings),
        representative: null,
        disposition: this.getTranscriptRequested(hearings),
        hearingHoldOpen: null,
        aod: null
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
        header: 'Prep',
        align: 'left',
        valueName: 'prep'
      },
      {
        header: 'Time/RO(s)',
        align: 'left',
        valueName: 'hearingTime'
      },
      {
        header: 'Appellant/Veteran ID',
        align: 'left',
        valueName: 'appellantInformation',
        span: (row) => row.representative ? 1 : 2
      },
      {
        header: 'Representative',
        align: 'left',
        valueName: 'representative',
        span: (row) => row.representative ? 1 : 0
      },
      {
        header: 'Actions',
        align: 'left',
        valueName: 'disposition'
      },
      {
        header: '',
        align: 'left',
        valueName: 'holdOpen'
      },
      {
        header: '',
        align: 'left',
        valueName: 'aod'
      }
    ];

    const docket = orderTheDocket(this.props.docket);

    return <div>
      <AppSegment extraClassNames="cf-hearings" noMarginTop filledBackground>
        <div className="cf-title-meta-right">
          <div className="title cf-hearings-title-and-judge">
            <h1>Daily Docket</h1>
            <span>VLJ: {this.props.veteran_law_judge.full_name}</span>
          </div>
          <div className="meta">
            <div>{moment(docket[0].scheduled_for).format('ddd l')}</div>
            <div>Hearing Type: {docket[0].request_type}</div>
          </div>
        </div>

        <div {...noMarginStyling}>
          <Table
            columns={dailyDocketColumns}
            rowObjects={this.getDailyDocketRows(docket)}
            summary="dailyDocket"
            bodyStyling={tableRowStyling}
            slowReRendersAreOk
          />
        </div>
      </AppSegment>
      <div className="cf-alt--actions">
        <div className="cf-push-left">
          <Link to="/hearings/dockets" onClick={this.onclickBackToHearingDays} >&lt; Back to Your Hearing Days</Link>
        </div>
      </div>
    </div>;
  }
}

const mapDispatchToProps = (dispatch) => bindActionCreators({
  setNotes,
  setDisposition,
  setHoldOpen,
  setAod,
  setHearingViewed,
  setTranscriptRequested,
  setHearingPrepped
}, dispatch);

export default connect(
  null,
  mapDispatchToProps
)(DailyDocket);

DailyDocket.propTypes = {
  veteran_law_judge: PropTypes.object.isRequired,
  hearing: PropTypes.object,
  hearingDate: PropTypes.string
};
