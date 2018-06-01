import React from 'react';
import PropTypes from 'prop-types';
import SearchableDropdown from '../../components/SearchableDropdown';
import ViewableItemLink from '../../components/ViewableItemLink';
import Textarea from 'react-textarea-autosize';
import Checkbox from '../../components/Checkbox';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import {
  setNotes, setDisposition, setHoldOpen, setAod, setTranscriptRequested, setHearingViewed,
  setHearingPrepped
} from '../actions/Dockets';
import moment from 'moment';
import 'moment-timezone';
import { getDateTime } from '../util/DateUtil';
import { css } from 'glamor';
import _ from 'lodash';
import { DISPOSITION_OPTIONS } from '../constants/constants';

const textareaStyling = css({
  '@media only screen and (max-width : 1024px)': {
    '& > textarea': {
      width: '80%'
    }
  }
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

export class DocketHearingRow extends React.PureComponent {

  setDisposition = (selected) =>
    this.props.setDisposition(this.props.hearing.id, selectedValue(selected), this.props.hearingDate);

  setHoldOpen = (selected) =>
    this.props.setHoldOpen(this.props.hearing.id, selectedValue(selected), this.props.hearingDate);

  setAod = (selected) =>
    this.props.setAod(this.props.hearing.id, selectedValue(selected), this.props.hearingDate);

  setTranscriptRequested = (value) =>
    this.props.setTranscriptRequested(this.props.hearing.id, value, this.props.hearingDate);

  setNotes = (event) => this.props.setNotes(this.props.hearing.id, event.target.value, this.props.hearingDate);

  setHearingViewed = () => this.props.setHearingViewed(this.props.hearing.id)

  preppedOnChange = (value) => this.props.setHearingPrepped({
    hearingId: this.props.hearing.id,
    prepped: value,
    date: this.props.hearingDate,
    setEdited: true
  });

  render() {
    const {
      index,
      hearing
    } = this.props;

    let roTimeZone = hearing.regional_office_timezone;

    let getRoTime = (date) => {
      return moment(date).tz(roTimeZone).
        format('h:mm a z').
        replace(/(\w)(DT|ST)/g, '$1T');
    };

    const appellantDisplay = <div>
      { _.isEmpty(hearing.appellant_mi_formatted) ||
        hearing.appellant_mi_formatted === hearing.veteran_mi_formatted ?
        (<b>{hearing.veteran_mi_formatted}</b>) :
        (<span><b>{hearing.appellant_mi_formatted}</b>
          {hearing.veteran_mi_formatted} (Veteran)</span>)
      }
    </div>;

    return <tbody>
      <tr>
        <td>
          <span>{index + 1}.</span>
        </td>
        <td className="cf-hearings-prepped">
          <span>
            <Checkbox
              id={`${hearing.id}-prep`}
              onChange={this.preppedOnChange}
              key={`${hearing.id}`}
              value={hearing.prepped || false}
              name={`${hearing.id}-prep`}
              hideLabel
              {...preppedCheckboxStyling}
              tabindex="1"
            />
          </span>
        </td>
        <td className="cf-hearings-docket-date">
          <span>
            {getDateTime(hearing.date)} /<br />
            {getRoTime(hearing.date)}
          </span>
          <span>
            {hearing.regional_office_name}
          </span>
        </td>
        <td className="cf-hearings-docket-appellant">
          {appellantDisplay}
          <ViewableItemLink
            tabindex="2"
            boldCondition={!hearing.viewed_by_current_user}
            onOpen={this.setHearingViewed}
            linkProps={{
              to: `/hearings/${hearing.id}/worksheet`,
              target: '_blank'
            }}>
            {hearing.vbms_id}
          </ViewableItemLink>
          <span {...issueCountStyling}>
            {hearing.current_issue_count} {hearing.current_issue_count === 1 ? 'Issue' : 'Issues' }
          </span>
        </td>
        <td className="cf-hearings-docket-rep">
          {hearing.representative}
          <span {...issueCountStyling}>
            {hearing.representative_name}
          </span>
        </td>
        <td className="cf-hearings-docket-actions" rowSpan="3">
          <SearchableDropdown
            label="Disposition"
            name={`${hearing.id}-disposition`}
            options={DISPOSITION_OPTIONS}
            onChange={this.setDisposition}
            value={hearing.disposition}
            searchable={false}
            tabindex="3"
          />
          <SearchableDropdown
            label="Hold Open"
            name={`${hearing.id}-hold_open`}
            options={holdOptions(this.props.hearingDate)}
            onChange={this.setHoldOpen}
            value={hearing.hold_open}
            searchable={false}
            tabindex="4"
          />
          <SearchableDropdown
            label="AOD"
            name={`${hearing.id}-aod`}
            options={aodOptions}
            onChange={this.setAod}
            value={hearing.aod}
            searchable={false}
            tabindex="5"
          />
          <div className="transcriptRequested">
            <Checkbox
              label="Transcript Requested"
              name={`${hearing.id}.transcript_requested`}
              value={hearing.transcript_requested}
              onChange={this.setTranscriptRequested}
              tabindex="7"
            />
          </div>
        </td>
      </tr>
      <tr>
        <td></td>
        <td></td>
        <td></td>
        <td colSpan="2" className="cf-hearings-docket-notes">
          <div>
            <label htmlFor={`${hearing.id}.notes`}>Notes</label>
            <div {...textareaStyling}>
              <Textarea
                id={`${hearing.id}.notes`}
                value={hearing.notes || ''}
                name="Notes"
                onChange={this.setNotes}
                maxLength="100"
                tabindex="6"
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
  setTranscriptRequested,
  setHearingPrepped
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
