import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import SearchableDropdown from '../components/SearchableDropdown';
import Checkbox from '../components/Checkbox';
import moment from 'moment';
import 'moment-timezone';
import { Link } from 'react-router-dom';

const dispositionOptions = [{ value: 'held',
  label: 'Held' },
{ value: 'noshow',
  label: 'No Show' },
{ value: 'canceled',
  label: 'Canceled' },
{ value: 'postponed',
  label: 'Postponed' }];

const holdOptions = [{ value: '30',
  label: '30 days' },
{ value: '60',
  label: '60 days' },
{ value: '90',
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

// This may go away in favor of the timestamp from updated record
const now = () => {
  return moment().
    format('h:mm a').
    replace(/(p|a)m/, '$1.m.');
};

export class DailyDocket extends React.Component {

  componentDidMount = () => {
    // TEMP logic to show Saving.../Last saved at <time>
    setInterval(() => {
      let text = document.getElementsByClassName('saving')[0].textContent;

      if (text.startsWith('Saving...')) {
        document.getElementsByClassName('saving')[0].innerHTML = `Last saved at ${now()}`;
      } else {
        document.getElementsByClassName('saving')[0].innerHTML = 'Saving...';
      }
    }, 3000);
  }

  render() {

    const docket = this.props.docket;

    return <div>
      <div className="cf-app-segment cf-app-segment--alt cf-hearings">
        <div className="cf-title-meta-right">
          <div className="title cf-hearings-title-and-judge">
            <h1>Daily Docket</h1>
            <span>VLJ: {this.props.veteran_law_judge.full_name}</span>
          </div>
          <div className="meta">
            <div>{moment(docket[0].date).format('ddd l')}</div>
            <div>Hearing Type: {docket[0].request_type}</div>
          </div>
        </div>
        <table className="cf-hearings-docket">
          <thead>
            <tr>
              <th>Time/Regional Office</th>
              <th>Appellant</th>
              <th>Representative</th>
              <th>
                <span>Actions</span>
                <span className="saving">Last saved at {now()}</span>
              </th>
            </tr>
          </thead>
          {docket.map((hearing, index) =>
          <tbody key={index}>
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
                  name={`disposition_${index}`}
                  options={dispositionOptions}
                  onChange={() => {
                    return true;
                  }}
                  searchable={true}
                />
                <SearchableDropdown
                  label="Hold Open"
                  name={`hold_${index}`}
                  options={holdOptions}
                  onChange={() => {
                    return true;
                  }}
                  searchable={true}
                />
                <SearchableDropdown
                  label="AOD"
                  name={`aod_${index}`}
                  options={aodOptions}
                  onChange={() => {
                    return true;
                  }}
                  searchable={true}
                />
                <div className="transcriptRequired">
                  <Checkbox
                    label="Transcript Requested"
                    vertical={true}
                    name={`transcript_requested_${index}`}
                    onChange={() => {
                      return true;
                    }}
                    value={false}
                  ></Checkbox>
                </div>
              </td>
            </tr>
            <tr>
              <td></td>
              <td colSpan="2" className="cf-hearings-docket-notes">
                <div>
                  <label htmlFor={`notes_${index}`}>Notes:</label>
                  <div>
                    <textarea id={`notes_${index}`} defaultValue="" />
                  </div>
                </div>
              </td>
            </tr>
          </tbody>
          )}
        </table>
      </div>
      <div className="cf-alt--actions cf-alt--app-width">
        <div className="cf-push-left">
          <Link to="/hearings/dockets">&lt; Back to Dockets</Link>
        </div>
      </div>
    </div>;
  }
}

const mapStateToProps = (state) => ({
  dockets: state.dockets,
  currentlyLiveHearing: state.currentlyLiveHearing
});

export default connect(
  mapStateToProps
)(DailyDocket);

DailyDocket.propTypes = {
  veteran_law_judge: PropTypes.object.isRequired
};
