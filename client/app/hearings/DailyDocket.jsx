import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import TextareaContainer from './TextareaContainer';
import DropdownContainer from './DropdownContainer';
import CheckboxContainer from './CheckboxContainer';
import AutosavePrompt from './AutosavePrompt';
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

export class DailyDocket extends React.Component {

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
                <AutosavePrompt spinnerColor="#68bd07" />
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
                <Link to={`/hearings/${hearing.id}/worksheet`}>{hearing.vbms_id}</Link>
              </td>
              <td className="cf-hearings-docket-rep">{hearing.representative_name}</td>
              <td className="cf-hearings-docket-actions" rowSpan="2">
                <DropdownContainer
                  label="Disposition"
                  name={`${hearing.id}:disposition`}
                  options={dispositionOptions}
                  defaultValue={hearing.disposition}
                  action="updateDailyDocketAction"
                  tabIndex={`${(index * 10) + 2}`}
                />
                <DropdownContainer
                  label="Hold Open"
                  name={`${hearing.id}:hold_open`}
                  options={holdOptions}
                  defaultValue={hearing.hold_open}
                  action="updateDailyDocketAction"
                  tabIndex={`${(index * 10) + 3}`}
                />
                <DropdownContainer
                  label="AOD"
                  name={`${hearing.id}:aod`}
                  options={aodOptions}
                  defaultValue={hearing.aod}
                  action="updateDailyDocketAction"
                  tabIndex={`${(index * 10) + 4}`}
                />
                <div className="transcriptRequested">
                  <CheckboxContainer
                    id={`${hearing.id}:transcript_requested`}
                    defaultValue={hearing.transcriptRequested}
                    action="updateDailyDocketTranscript"
                    tabIndex={`${(index * 10) + 5}`}
                  ></CheckboxContainer>
                </div>
              </td>
            </tr>
            <tr>
              <td></td>
              <td colSpan="2" className="cf-hearings-docket-notes">
                <div>
                  <label htmlFor={`${hearing.id}:notes`}>Notes:</label>
                  <div>
                    <TextareaContainer
                      id={`${hearing.id}:notes`}
                      defaultValue={hearing.notes}
                      action="updateDailyDocketNotes"
                      maxLength="100"
                      tabIndex={`${(index * 10) + 1}`}
                    />
                  </div>
                </div>
              </td>
            </tr>
          </tbody>
          )}
        </table>
      </div>
      <div className="cf-actions cf-app-width">
        <div className="cf-push-left">
          <Link to="/hearings/dockets">&lt; Back to Dockets</Link>
        </div>
      </div>
    </div>;
  }
}

const mapStateToProps = (state) => ({
  dockets: state.dockets
});

export default connect(
  mapStateToProps
)(DailyDocket);

DailyDocket.propTypes = {
  veteran_law_judge: PropTypes.object.isRequired
};
