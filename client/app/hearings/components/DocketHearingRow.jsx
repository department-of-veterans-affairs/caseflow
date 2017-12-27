import React from 'react';
import PropTypes from 'prop-types';
import SearchableDropdown from '../../components/SearchableDropdown';
import ViewableItemLink from '../../components/ViewableItemLink';
import Textarea from 'react-textarea-autosize';
import Checkbox from '../../components/Checkbox';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import {
  setNotes, setDisposition, setHoldOpen, setAod, setTranscriptRequested, setHearingViewed
} from '../actions/Dockets';
import moment from 'moment';
import 'moment-timezone';
import { getDate } from '../util/DateUtil';

const dispositionOptions = [{ value: 'held',
  label: 'Held' },
{ value: 'no_show',
  label: 'No Show' },
{ value: 'cancelled',
  label: 'Cancelled' },
{ value: 'postponed',
  label: 'Postponed' }];

const holdOptions = [
  { value: 0,
    label: '0 days' },
  { value: 30,
    label: '30 days' },
  { value: 60,
    label: '60 days' },
  { value: 90,
    label: '90 days' }];

const aodOptions = [{ value: 'granted',
  label: 'Granted' },
{ value: 'filed',
  label: 'Filed' },
{ value: 'none',
  label: 'None' }];

export class DocketHearingRow extends React.PureComponent {

  setDisposition = ({ value }) => this.props.setDisposition(this.props.index, value, this.props.hearingDate);

  setHoldOpen = ({ value }) => this.props.setHoldOpen(this.props.index, value, this.props.hearingDate);

  setAod = ({ value }) => this.props.setAod(this.props.index, value, this.props.hearingDate);

  setTranscriptRequested = (value) =>
    this.props.setTranscriptRequested(this.props.index, value, this.props.hearingDate);

  setNotes = (event) => this.props.setNotes(this.props.index, event.target.value, this.props.hearingDate);

  setHearingViewed = () => this.props.setHearingViewed(this.props.hearing.id)

  render() {
    const {
      index,
      hearing
    } = this.props;

    let roTimeZone = hearing.regional_office_timezone;

    let getRoTime = (date) => {
      return moment(date).tz(roTimeZone).
        format('h:mm a z');
    };

    const appellantDisplay = hearing.appellant_last_first_mi ? hearing.appellant_last_first_mi : hearing.veteran_name;

    return <tbody>
      <tr>
        <td className="cf-hearings-docket-date">
          <span>{index + 1}.</span>
          <span>
            {getDate(hearing.date)} /<br />
            {getRoTime(hearing.date)}
          </span>
          <span>
            {hearing.regional_office_name}
          </span>
        </td>
        <td className="cf-hearings-docket-appellant">
          <b>{appellantDisplay}</b>
          <ViewableItemLink
            boldCondition={!hearing.viewed_by_current_user}
            onOpen={this.setHearingViewed}
            linkProps={{
              to: `/hearings/${hearing.id}/worksheet`,
              target: '_blank'
            }}>
            {hearing.vbms_id}
          </ViewableItemLink>
        </td>
        <td className="cf-hearings-docket-rep">{hearing.representative}</td>
        <td className="cf-hearings-docket-actions" rowSpan="3">
          <SearchableDropdown
            label="Disposition"
            name={`${hearing.id}.disposition`}
            options={dispositionOptions}
            onChange={this.setDisposition}
            value={hearing.disposition}
            searchable={false}
          />
          <SearchableDropdown
            label="Hold Open"
            name={`${hearing.id}.hold_open`}
            options={holdOptions}
            onChange={this.setHoldOpen}
            value={hearing.hold_open}
            searchable={false}
          />
          <SearchableDropdown
            label="AOD"
            name={`${hearing.id}.aod`}
            options={aodOptions}
            onChange={this.setAod}
            value={hearing.aod}
            searchable={false}
          />
          <div className="transcriptRequested">
            <Checkbox
              label="Transcript Requested"
              name={`${hearing.id}.transcript_requested`}
              value={hearing.transcript_requested}
              onChange={this.setTranscriptRequested}
            />
          </div>
        </td>
      </tr>
      <tr>
        <td></td>
        <td colSpan="2">
          {hearing.issue_count} {hearing.issue_count === 1 ? 'Issue' : 'Issues' }
        </td>
      </tr>
      <tr>
        <td></td>
        <td colSpan="2" className="cf-hearings-docket-notes">
          <div>
            <label htmlFor={`${hearing.id}.notes`}>Notes</label>
            <div>
              <Textarea
                id={`${hearing.id}.notes`}
                value={hearing.notes || ''}
                name="Notes"
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
  setAod,
  setHearingViewed,
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
