import React from 'react';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import Checkbox from '../../components/Checkbox';

import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { css } from 'glamor';
import { populateDailyDocket, getDailyDocket, getWorksheet, setHearingPrepped } from '../actions/Dockets';
import { getReaderLink } from '../util/index';
import SearchableDropdown from '../../components/SearchableDropdown';
import _ from 'lodash';
import moment from 'moment';

const headerSelectionStyling = css({
  display: 'block',
  padding: '8px 20px 10px 30px',
  height: '90px',
  backgroundColor: '#E4E2E0',
  '.question-label': {
    marginBottom: '5px'
  }
});

const hearingPreppedStyling = css({
  marginTop: '4rem',
  marginBottom: '4rem',
  marginLeft: '20px'
});

const containerStyling = css({
  width: '1000px',
  display: 'flex'
});

const selectVeteranStyling = css({
  width: '350px'
});

class WorksheetHeaderVeteranSelection extends React.PureComponent {

  componentDidMount() {
    const dailyDocket = JSON.parse(localStorage.getItem('dailyDocket'));

    this.date = localStorage.getItem('dailyDocketDate') ||
      moment(this.props.worksheet.date).format('YYYY-MM-DD');

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

  openPdf = (worksheet, worksheetIssues) => () => {
    Promise.resolve([this.save(worksheet, worksheetIssues)()]).then(() => {
      window.open(`${window.location.pathname}/print`, '_blank');
    });
  };

  getDocketVeteranOptions = (dailyDocket, worksheetIssues) => (
    _.isEmpty(dailyDocket[this.date]) ?
      [] :
      dailyDocket[this.date].map((hearing) => ({
        label: `${hearing.veteran_fi_last_formatted} (${_.size(worksheetIssues)} issues)`,
        value: hearing.id
      }))
  );

  preppedOnChange = (value) => this.props.setHearingPrepped(this.props.worksheet.id, value, this.date);

  render() {

    const { worksheet, worksheetIssues } = this.props;

    return <span className="worksheet-header" {...headerSelectionStyling}>
      <div className="cf-push-left" {...containerStyling}>
        <div {...selectVeteranStyling}>
          <SearchableDropdown
            label="Select Veteran"
            name="worksheet-veteran-selection"
            placeholder="Hello there"
            options={this.getDocketVeteranOptions(this.props.dailyDocket, worksheetIssues)}
            onChange={this.onDropdownChange}
            value={worksheet.id}
            searchable={false}
          />
        </div>
        <Checkbox
          id={`${worksheet.id}-prep`}
          onChange={this.preppedOnChange}
          value={worksheet.prepped}
          name={`${worksheet.id}-prep`}
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
    setHearingPrepped
  }, dispatch)
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(WorksheetHeaderVeteranSelection);
