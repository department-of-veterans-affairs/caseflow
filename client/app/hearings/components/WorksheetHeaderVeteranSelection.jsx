import React from 'react';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import Checkbox from '../../components/Checkbox';
import FoundIcon from '../../components/FoundIcon';

import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { css } from 'glamor';
import { populateDailyDocket, getDailyDocket, getWorksheet, 
  onHearingPrepped, setHearingPrepped, saveWorksheet } from '../actions/Dockets';
import { getReaderLink } from '../util/index';
import SearchableDropdown from '../../components/SearchableDropdown';
import _ from 'lodash';
import moment from 'moment';

const headerSelectionStyling = css({
  display: 'block',
  padding: '8px 30px 10px 30px',
  height: '90px',
  backgroundColor: '#E4E2E0'
});

const hearingPreppedStyling = css({
  margin: '4rem 4rem 0 1.75rem'
});

const containerStyling = css({
  width: '70%',
  display: 'flex'
});

const selectVeteranStyling = css({
  width: '350px'
});

class WorksheetHeaderVeteranSelection extends React.PureComponent {

  componentDidMount() {
    // Getting the stored worksheet information from the local storage.
    const dailyDocket = JSON.parse(localStorage.getItem('dailyDocket'));

    this.date = localStorage.getItem('dailyDocketDate') ||
      moment(this.props.worksheet.date).format('YYYY-MM-DD');

    // If the local storage information exists, populate the daily docket
    // and the date. Also remove the information from local storage.
    if (dailyDocket && dailyDocket[this.date]) {
      this.props.populateDailyDocket(dailyDocket, this.date);
      localStorage.removeItem('dailyDocket');
      localStorage.removeItem('dailyDocketDate');
    } else {
      this.props.getDailyDocket(dailyDocket, this.date);
    }
  }

  onDropdownChange = (value) => {
    if (value) {
      this.props.history.push(`/hearings/${value.value}/worksheet`);
    }
  }

  saveWorksheet = (worksheet) => {
    this.props.saveWorksheet(worksheet, true);
  }

  getOptionLabel = (hearing) => (
    <div>
      {hearing.veteran_fi_last_formatted}  ({hearing.issue_count} {hearing.issue_count === 1 ?
        'issue' : 'issues'}){'  '}{hearing.prepped ? <FoundIcon /> : ''}
    </div>
  );

  getDocketVeteranOptions = (dailyDocket) => (
    _.isEmpty(dailyDocket[this.date]) ?
      [] :
      dailyDocket[this.date].map((hearing) => ({
        label: this.getOptionLabel(hearing),
        value: hearing.id
      }))
  );

  preppedOnChange = (value) => {
    this.props.onHearingPrepped(value);
    this.saveWorksheet(this.props.worksheet);
  }

  render() {

    const { worksheet, worksheetIssues } = this.props;

    return <span className="worksheet-header" {...headerSelectionStyling}>
      <div className="cf-push-left" {...containerStyling}>
        <div {...selectVeteranStyling}>
          <SearchableDropdown
            label="Select Veteran"
            name="worksheet-veteran-selection"
            placeholder=""
            options={this.getDocketVeteranOptions(this.props.dailyDocket, worksheetIssues)}
            onChange={this.onDropdownChange}
            value={worksheet.id}
            searchable={false}
          />
        </div>
        <Checkbox
          id={`prep-${worksheet.id}`}
          onChange={this.preppedOnChange}
          value={worksheet.prepped || false}
          name={`prep-${worksheet.id}`}
          label="Hearing Prepped"
          styling={hearingPreppedStyling}
        />
      </div>
      <div className="cf-push-right">
        <Link
          name="review-efolder"
          href={`${getReaderLink(worksheet)}?category=case_summary`}
          button="primary"
          target="_blank">
        Review eFolder</Link>
      </div>
    </span>;
  }
}

const mapStateToProps = (state) => ({
  dailyDocket: state.dailyDocket,
  worksheet: state.worksheet,
  worksheetIssues: state.worksheetIssues
});

const mapDispatchToProps = (dispatch) => ({
  ...bindActionCreators({
    populateDailyDocket,
    getDailyDocket,
    getWorksheet,
    onHearingPrepped,
    setHearingPrepped,
    saveWorksheet
  }, dispatch)
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(WorksheetHeaderVeteranSelection);
