import React from 'react';
import PropTypes from 'prop-types';
import SearchableDropdown from '../components/SearchableDropdown';
import Checkbox from '../components/Checkbox';
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

export default class DocketHearingRow extends React.Component {

  render() {
    const {
      index,
      hearing,
      hearingDate,
      setNotes,
      setDisposition,
      setHoldOpen,
      setAOD,
      setTranscriptRequested
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
            name="Disposition"
            options={dispositionOptions}
            onChange={(valueObject) => setDisposition(index, valueObject.value, hearingDate)}
            value={hearing.disposition}
            searchable={true}
          />
          <SearchableDropdown
            label="Hold Open"
            name="Hold Open"
            options={holdOptions}
            onChange={(valueObject) => setHoldOpen(index, valueObject.value, hearingDate)}
            value={hearing.hold_open}
            searchable={true}
          />
          <SearchableDropdown
            label="AOD"
            name="AOD"
            options={aodOptions}
            onChange={(valueObject) => setAOD(index, valueObject.value, hearingDate)}
            value={hearing.aod}
            searchable={true}
          />
          <div className="transcriptRequested">
            <Checkbox
              label="Transcript Requested"
              name="Transcript Requested"
              value={hearing.transcriptRequested}
              onChange={(value) => setTranscriptRequested(index, value, hearingDate)}
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
                onChange={(event) => setNotes(index, event.target.value, hearingDate)}
                maxLength="100"
              />
            </div>
          </div>
        </td>
      </tr>
    </tbody>;
  }
}

DocketHearingRow.propTypes = {
  index: PropTypes.number.isRequired,
  hearing: PropTypes.object.isRequired,
  hearingDate: PropTypes.string.isRequired,
  setNotes: PropTypes.func.isRequired,
  setDisposition: PropTypes.func.isRequired,
  setHoldOpen: PropTypes.func.isRequired,
  setAOD: PropTypes.func.isRequired,
  setTranscriptRequested: PropTypes.func.isRequired
};
