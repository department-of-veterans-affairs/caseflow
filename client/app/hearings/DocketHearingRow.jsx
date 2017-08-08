import React from 'react';
import PropTypes from 'prop-types';
import SearchableDropdown from '../components/SearchableDropdown';
import Checkbox from '../components/Checkbox';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { setNotes, setDisposition, setHoldOpen, setAOD, setTranscriptRequested } from './actions/Dockets';
import moment from 'moment';
import 'moment-timezone';
import { Link } from 'react-router-dom';

const dispositionOptions = [{ value: 'held',
  label: 'Held' },
{ value: 'no_show',
  label: 'No Show' },
{ value: 'cancelled',
  label: 'Cancelled' },
{ value: 'postponed',
  label: 'Postponed' }];

const holdOptions = [{ value: 30,
  label: '30 days' },
{ value: 60,
  label: '60 days' },
{ value: 90,
  label: '90 days' }];

const aodOptions = [{ value: 'grant',
  label: 'Grant' },
{ value: 'filed',
  label: 'Filed' },
{ value: 'none',
  label: 'None' }];

const getDate = (date, timezone) => {
  return moment.tz(date, timezone).
    format('h:mm a z').
    replace(/(p|a)m/, '$1.m.');
};

export class DocketHearingRow extends React.Component {

  setDisposition = (valueObject) =>
      this.props.setDisposition(this.props.index, valueObject.value, this.props.hearingDate);

  setHoldOpen = (valueObject) => this.props.setHoldOpen(this.props.index, valueObject.value, this.props.hearingDate);

  setAOD = (valueObject) => this.props.setAOD(this.props.index, valueObject.value, this.props.hearingDate);

  setTranscriptRequested = (value) =>
      this.props.setTranscriptRequested(this.props.index, value, this.props.hearingDate);

  setNotes = (event) => this.props.setNotes(this.props.index, event.target.value, this.props.hearingDate);

  render() {
    const {
      index,
      hearing,
      hearingDate
    } = this.props;

    return <tbody>
      <tr>
        <td className="cf-hearings-docket-date">
          <span>{index + 1}.</span>
          <span>
            {getDate(hearing.date, hearing.venue.timezone)}
            <br/>
            {`${hearing.venue.city}, ${hearing.venue.state}`}
          </span>
        </td>
        <td className="cf-hearings-docket-appellant">
          <b>{hearing.appellant_last_first_mi}</b>
          <Link to={`/hearings/worksheets/${hearing.vbms_id}`}>{hearing.vbms_id}</Link>
        </td>
        <td className="cf-hearings-docket-rep">{hearing.representative_name}</td>
        <td className="cf-hearings-docket-actions" rowSpan="2">
          <SearchableDropdown
            label="Disposition"
            name={`hearing.${this.props.date}.${index}.${hearing.id}.disposition`}
            options={dispositionOptions}
            onChange={this.setDisposition}
            value={hearing.disposition}
            searchable={true}
          />
          <SearchableDropdown
            label="Hold Open"
            name={`hearing.${this.props.date}.${index}.${hearing.id}.hold_open`}
            options={holdOptions}
            onChange={this.setHoldOpen}
            value={hearing.hold_open}
            searchable={true}
          />
          <SearchableDropdown
            label="AOD"
            name={`hearing.${this.props.date}.${index}.${hearing.id}.aod`}
            options={aodOptions}
            onChange={this.setAOD}
            value={hearing.aod}
            searchable={true}
          />
          <div className="transcriptRequested">
            <Checkbox
              label="Transcript Requested"
              name={`hearing.${this.props.date}.${index}.${hearing.id}.transcript_requested`}
              value={hearing.transcriptRequested}
              onChange={this.setTranscriptRequested}
            />
          </div>
        </td>
      </tr>
      <tr>
        <td></td>
        <td colSpan="2" className="cf-hearings-docket-notes">
          <div>
            <label htmlFor={`hearing.${hearingDate}.${index}.${hearing.id}.notes`}>Notes:</label>
            <div>
              <textarea
                id={`hearing.${hearingDate}.${index}.${hearing.id}.notes`}
                defaultValue={hearing.notes}
                onChange={this.setNotes}
                maxLength="100"
              />
            </div>
          </div>
        </td>
      </tr>
    </tbody>;
  }
}

const mapDispatchToProps = (dispatch) => bindActionCreators({
  setNotes,
  setDisposition,
  setHoldOpen,
  setAOD,
  setTranscriptRequested
}, dispatch);

export default connect(
  null,
  mapDispatchToProps
)(DocketHearingRow);

DocketHearingRow.propTypes = {
  index: PropTypes.number.isRequired,
  hearing: PropTypes.object.isRequired,
  hearingDate: PropTypes.string.isRequired
};
