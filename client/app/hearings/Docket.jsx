import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import SearchableDropdown from '../components/SearchableDropdown';
import Checkbox from '../components/Checkbox';
import TextareaField from '../components/TextareaField';
import moment from 'moment';
import 'moment-timezone';

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

const getDate = (date, hearing) => {
  return moment.tz(date, hearing.venue.timezone).
    format('h:mm a z').
    replace(/(p|a)m/, '$1.m.');
};

// This may go away in favor of the timestamp from updated record
const now = () => {
  return moment().
    format('h:mm a').
    replace(/(p|a)m/, '$1.m.');
};

export class Docket extends React.Component {

  render() {

    // TEMP logic for seeing save...
    if (!this.state) {
      this.state = {
        saving: false,
        saved: true
      };
    }
    setTimeout(() => {
      this.setState({ saving: !this.state.saving,
        saved: !this.state.saved });
    }, 3000);

    return <div className="cf-hearings">
      <div className="cf-title-meta-right">
        <div className="cf-push-left">
          <div className="cf-hearings-title-and-judge">
            <h1>Daily Docket</h1>
            <span>VLJ: {this.props.veteran_law_judge.full_name}</span>
          </div>
        </div>
        <div className="cf-push-right">
          <div>{moment(this.props.hearings[0].date).format('ddd l')}</div>
          <div>Hearing Type: {this.props.hearings[0].type}</div>
        </div>
      </div>
      <table className="cf-hearings-docket">
        <thead>
          <tr>
            <th>Time/Field Office</th>
            <th>Appellant</th>
            <th>Representative</th>
            <th>
              <span>Actions</span>
              {this.state.saving && <span className="saving">Saving...</span>}
              {this.state.saved &&
              <span className="saving">
                Last saved at {now()}
              </span>
              }
              {!this.state.saving && !this.state.saved &&
              <span>
                &nbsp;
              </span>
              }
            </th>
          </tr>
        </thead>
        {this.props.hearings.map((hearing, index) =>
        <tbody key={index}>
          <tr>
            <td className="cf-hearings-docket-date">
              <span>{index + 1}.</span>
              <span>
                {getDate(hearing.date, this.props.hearings[0])}
                <br/>
                {`${hearing.venue.city}, ${hearing.venue.state}`}
              </span>
            </td>
            <td className="cf-hearings-docket-appellant">
              <b>{hearing.appellant}</b>
              <a href="#">{hearing.vbms_id}</a>
            </td>
            <td className="cf-hearings-docket-rep">{hearing.representative}</td>
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
                <TextareaField
                  id={`notes_${index}`}
                  label="Notes"
                  name={`notes_${index}`}
                  value=""
                  onChange={() => {
                    return true;
                  }}
                />
              </div>
            </td>
          </tr>
        </tbody>
        )}
      </table>
    </div>;
  }
}

const mapStateToProps = (state) => ({
  hearings: state.hearings
});

const mapDispatchToProps = () => ({
  // TODO: pass dispatch into method and use it
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(Docket);

Docket.propTypes = {
  veteran_law_judge: PropTypes.object.isRequired,
  hearings: PropTypes.arrayOf(PropTypes.object).isRequired
};
