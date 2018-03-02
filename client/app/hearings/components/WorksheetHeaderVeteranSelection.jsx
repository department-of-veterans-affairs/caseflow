import React from 'react';
import PropTypes from 'prop-types';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import Checkbox from '../../components/Checkbox';
import FoundIcon from '../../components/FoundIcon';

import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { css } from 'glamor';
import { populateDailyDocket, getDailyDocket, getWorksheet,
  setPrepped } from '../actions/Dockets';
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
    this.date = moment(this.props.worksheet.date).format('YYYY-MM-DD');
    this.props.getDailyDocket(null, this.date);
  }

  onDropdownChange = (value) => {
    if (value) {
      this.props.save();
      this.props.history.push(`/hearings/${value.value}/worksheet`);
    }
  }

  getOptionLabel = (hearing) => (
    <div>
      {hearing.veteran_fi_last_formatted}  ({hearing.issue_count} {hearing.issue_count === 1 ?
        'issue' : 'issues'}){'  '}{hearing.prepped ? <FoundIcon /> : ''}
    </div>
  );

  getDocketVeteranOptions = (docket) => (
    _.isEmpty(docket) ?
      [] :
      docket.map((hearing) => ({
        label: this.getOptionLabel(hearing),
        value: hearing.id
      }))
  );

  savePrepped = (hearingId, value) => this.props.setPrepped(hearingId, value, this.date);

  preppedOnChange = (value) => this.savePrepped(this.props.worksheet.id, value);

  render() {

    const { worksheet, worksheetIssues, dailyDocket } = this.props;
    const currentDocket = dailyDocket[this.date] || {};

    // getting the hearing information from the daily docket for the prepped field
    // in the header
    const hearingIndex = _.findIndex(currentDocket, { id: worksheet.id });
    const currentHearing = currentDocket[hearingIndex] || {};

    return <span className="worksheet-header" {...headerSelectionStyling}>
      <div className="cf-push-left" {...containerStyling}>
        <div {...selectVeteranStyling}>
          <SearchableDropdown
            label="Select Veteran"
            name="worksheet-veteran-selection"
            placeholder=""
            options={this.getDocketVeteranOptions(currentDocket, worksheetIssues)}
            onChange={this.onDropdownChange}
            value={worksheet.id}
            searchable={false}
          />
        </div>
        <Checkbox
          id={`prep-${currentHearing.id}`}
          onChange={this.preppedOnChange}
          value={currentHearing.prepped || false}
          name={`prep-${currentHearing.id}`}
          label="Hearing Prepped"
          styling={hearingPreppedStyling}
        />
      </div>
      <div className="cf-push-right">
        <Link
          name="review-claims-folder"
          href={`${getReaderLink(worksheet.appeal_vacols_id)}?category=case_summary`}
          button="primary"
          target="_blank">
        Review claims folder</Link>
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
    setPrepped
  }, dispatch)
});

WorksheetHeaderVeteranSelection.propTypes = {
  worksheet: PropTypes.object.isRequired,
  worksheetIssues: PropTypes.object.isRequired,
  dailyDocket: PropTypes.object.isRequired,
  save: PropTypes.func.isRequired
};

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(WorksheetHeaderVeteranSelection);
