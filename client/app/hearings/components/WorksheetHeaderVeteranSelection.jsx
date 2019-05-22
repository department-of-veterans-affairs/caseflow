import React from 'react';
import PropTypes from 'prop-types';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import Checkbox from '../../components/Checkbox';
import FoundIcon from '../../components/FoundIcon';
import { LOGO_COLORS } from '../../constants/AppConstants';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { css } from 'glamor';
import { setPrepped, getHearingDayHearings } from '../actions/Dockets';
import { getReaderLink } from '../util/index';
import SearchableDropdown from '../../components/SearchableDropdown';
import SmallLoader from '../../components/SmallLoader';
import _ from 'lodash';
import { CATEGORIES, ACTIONS } from '../analytics';

const headerSelectionStyling = css({
  display: 'block',
  padding: '8px 30px 10px 30px',
  height: '90px',
  backgroundColor: '#f1f1f1',
  color: '#212121'
});

const hearingPreppedStyling = css({
  margin: '4rem 4rem 0 1.75rem'
});

const containerStyling = css({
  width: '60%',
  display: 'flex'
});

const selectVeteranStyling = css({
  width: '350px'
});

const buttonHeaderStyling = css({
  width: '40%',
  display: 'flex'
});

class WorksheetHeaderVeteranSelection extends React.PureComponent {

  componentDidMount() {
    this.props.getHearingDayHearings(this.props.worksheet.hearing_day_id);
  }

  onDropdownChange = (value) => {
    window.analyticsEvent(CATEGORIES.HEARING_WORKSHEET_PAGE, ACTIONS.SELECT_VETERAN_FROM_DROPDOWN);
    if (value) {
      this.props.save();
      this.props.history.push(`/${value.value}/worksheet`);
    }
  }

  getOptionLabel = (hearing) => (
    <div>
      {`${hearing.veteran_first_name[0]}. ${hearing.veteran_last_name} `}
      ({hearing.current_issue_count} {hearing.current_issue_count === 1 ? 'issue' : 'issues'})
      {'  '}{hearing.prepped ? <FoundIcon /> : ''}
    </div>
  );

  getDocketVeteranOptions = (docket) => (
    _.isEmpty(docket) ?
      [] :
      _.map(docket, (hearing) => ({
        label: this.getOptionLabel(hearing),
        value: hearing.external_id
      }))
  );

  preppedOnChange = (value) => this.props.setPrepped(this.props.worksheet.external_id, value);

  onClickReviewClaimsFolder = () =>
    window.analyticsEvent(CATEGORIES.HEARING_WORKSHEET_PAGE, ACTIONS.CLICK_ON_REVIEW_CLAIMS_FOLDER);

  render() {

    const { worksheet, worksheetIssues, hearings } = this.props;

    const docketNotLoaded = _.isEmpty(hearings);

    const currentHearing = docketNotLoaded ? {} : hearings[worksheet.external_id];

    return <span className="worksheet-header" {...headerSelectionStyling}>
      <div className="cf-push-left" {...containerStyling}>
        <div {...selectVeteranStyling}>
          <SearchableDropdown
            label="Select Veteran"
            name="worksheet-veteran-selection"
            placeholder={docketNotLoaded ? <SmallLoader spinnerColor={LOGO_COLORS.HEARINGS.ACCENT}
              message="Loading..." /> : ''}
            options={this.getDocketVeteranOptions(hearings, worksheetIssues)}
            onChange={this.onDropdownChange}
            value={worksheet.external_id}
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
          disabled={docketNotLoaded}
        />
      </div>
      <div className="cf-push-right" {...buttonHeaderStyling} >
        <Link
          name="view-case-detail"
          href={`/queue/appeals/${worksheet.appeal_external_id}`}
          button="primary"
          target="_blank">
         View case details</Link>
        <Link
          name="review-claims-folder"
          onClick={this.onClickReviewClaimsFolder}
          href={`${getReaderLink(worksheet.appeal_external_id)}?category=case_summary`}
          button="primary"
          target="_blank">
        Review claims folder</Link>
      </div>
    </span>;
  }
}

const mapStateToProps = (state) => ({
  hearings: state.hearings.hearings,
  worksheet: state.hearings.worksheet,
  worksheetIssues: state.hearings.worksheetIssues
});

const mapDispatchToProps = (dispatch) => ({
  ...bindActionCreators({
    setPrepped,
    getHearingDayHearings
  }, dispatch)
});

WorksheetHeaderVeteranSelection.propTypes = {
  worksheet: PropTypes.object.isRequired,
  worksheetIssues: PropTypes.object.isRequired,
  save: PropTypes.func.isRequired
};

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(WorksheetHeaderVeteranSelection);
