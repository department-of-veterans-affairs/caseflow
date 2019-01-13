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
  setHearingPrepped, setEvidenceWindowWaived
} from './actions/Dockets';
import { css } from 'glamor';
import _ from 'lodash';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { DISPOSITION_OPTIONS } from './constants/constants';
import Checkbox from '../components/Checkbox';
import ViewableItemLink from '../components/ViewableItemLink';
import Textarea from 'react-textarea-autosize';
import DocketTypeBadge from '../components/DocketTypeBadge';

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

  setEvidenceWindowWaived = (hearingId, hearingDate) => (value) => {
    this.props.setEvidenceWindowWaived(hearingId, value, hearingDate);
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
   if (hearing.appellant_first_name && hearing.appellant_last_name) {
     return <div>
       <span><b>{`${hearing.appellant_first_name} ${hearing.appellant_last_name}`}</b><br />
         {`${hearing.veteran_first_name} ${hearing.veteran_last_name}`} (Veteran)</span><br />
       <Link
         to={`/queue/appeals/${hearing.appeal_external_id}`}
         name={hearing.veteran_file_number} >
         {hearing.veteran_file_number}
       </Link>
       <div>
         <DocketTypeBadge name={hearing.docket_name} number={hearing.docket_number} />
         {hearing.docket_number}
       </div>
       <span {...issueCountStyling}>
         {hearing.current_issue_count} {hearing.current_issue_count === 1 ? 'Issue' : 'Issues' }
       </span>
     </div>;
   }

   return <div><b>{`${hearing.veteran_first_name} ${hearing.veteran_last_name}`}</b><br />
     <Link
       to={`/queue/appeals/${hearing.appeal_external_id}`}
       name={hearing.veteran_file_number} >
       {hearing.veteran_file_number}
     </Link>
     <div>
       <DocketTypeBadge name={hearing.docket_name} number={hearing.docket_number} />
       {hearing.docket_number}
     </div>
     <span {...issueCountStyling}>
       {hearing.current_issue_count} {hearing.current_issue_count === 1 ? 'Issue' : 'Issues' }
     </span>
   </div>;

 };

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

  getWaiveEvidenceCheckbox = (hearing) => {
    return <div>
      <h3>Waive 90 Day Evidence Hold</h3>
      <Checkbox
        label="Yes, Waive 90 Day Hold"
        name={`${hearing.id}.evidence_window_waived`}
        value={hearing.evidence_window_waived || false}
        onChange={this.setEvidenceWindowWaived(hearing.id, getDate(hearing.scheduled_for))}
      />
    </div>;
  };

  getTranscriptRequested = (hearing) => {
    return <div>
      {(hearing.docket_name === 'hearing') ? this.getWaiveEvidenceCheckbox(hearing) : null }
      <h3>Copy Requested by Appellant/Rep</h3>
      <Checkbox
        label="Transcript Requested"
        name={`${hearing.id}.transcript_requested`}
        value={hearing.transcript_requested || false}
        onChange={this.setTranscriptRequested(hearing.id, getDate(hearing.scheduled_for))}
      />
      <h3>Hearing Prep Worksheet</h3>
      <ViewableItemLink
        boldCondition={!hearing.viewed_by_current_user}
        onOpen={this.setHearingViewed(hearing.id)}
        linkProps={{
          to: `/hearings/${hearing.external_id}/worksheet`,
          target: '_blank'
        }}>
        Edit VLJ Hearing Worksheet
      </ViewableItemLink>
    </div>;
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
    if (hearing.docket_name === 'hearing') {
      return null;
    }

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
  };

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

  getDailyDocketRow = (hearing, count) => {
    return [{
      number: <b>{count}.</b>,
      prep: this.getPrepCheckBox(hearing),
      hearingTime: this.getRoTime(hearing),
      appellantInformation: this.getAppellantInformation(hearing),
      representative: <span>{hearing.representative}<br />{hearing.representative_name}</span>,
      disposition: this.getDispositionDropdown(hearing),
      holdOpen: this.getHoldOpenDropdown(hearing),
      aod: this.getAodDropdown(hearing)
    },
    {
      number: null,
      prep: null,
      hearingTime: null,
      appellantInformation: this.getNotesField(hearing),
      representative: null,
      disposition: this.getTranscriptRequested(hearing),
      hearingHoldOpen: null,
      aod: null
    }];
  };

  getDailyDocketRows = (hearings) => {
    let dailyDocketRows = [];
    let count = 0;

    _.forEach(hearings, (hearing) => {
      count += 1;

      const dailyDocketRow = this.getDailyDocketRow(hearing, count);

      dailyDocketRows.push(dailyDocketRow[0], dailyDocketRow[1]);
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
        valueName: 'disposition',
        span: (row) => row.representative ? 1 : 2
      },
      {
        header: '',
        align: 'left',
        valueName: 'aod'
      },
      {
        header: '',
        align: 'left',
        valueName: 'holdOpen',
        span: (row) => row.representative ? 1 : 0
      }
    ];

    const docket = orderTheDocket(this.props.docket);

    return <div>
      <AppSegment extraClassNames="cf-hearings" noMarginTop filledBackground>
        <div className="cf-title-meta-right">
          <div className="title cf-hearings-title-and-judge">
            <h1>Daily Docket ({moment(docket[0].scheduled_for).format('ddd l')})</h1>
            <span>VLJ: {this.props.veteran_law_judge.full_name}</span>
          </div>
          <span className="cf-push-right">
            VLJ: {docket[0].judge ? docket[0].judge.full_name : null}<br />
            Hearing Type: {docket[0].readable_request_type}<br />
          </span>
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
  setEvidenceWindowWaived,
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
