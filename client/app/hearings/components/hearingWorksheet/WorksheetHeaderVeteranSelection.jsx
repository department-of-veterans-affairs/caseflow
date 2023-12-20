import React from 'react';
import PropTypes from 'prop-types';
import { withRouter } from 'react-router-dom';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import Checkbox from '../../../components/Checkbox';
import FoundIcon from '../../../components/FoundIcon';
import { LOGO_COLORS } from '../../../constants/AppConstants';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { css } from 'glamor';
import { setPrepped, getHearingDayHearings } from '../../actions/hearingWorksheetActions';
import SearchableDropdown from '../../../components/SearchableDropdown';
import SmallLoader from '../../../components/SmallLoader';
import _ from 'lodash';
import ApiUtil from '../../../util/ApiUtil';
import { formatNameShort } from '../../../util/FormatUtil';

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
    ApiUtil.get(`/hearings/hearing_day/${this.props.worksheet.hearing_day_id}`).
      then((response) => {
        this.props.getHearingDayHearings(_.keyBy(response.body.hearing_day.hearings, 'external_id'));
      });
  }

  onDropdownChange = (value) => {
    if (value) {
      this.props.history.push(`/${value.value}/worksheet`);
      location.reload();
    }
  };

  getOptionLabel = (hearing) => (
    <div>
      {`${formatNameShort(hearing.veteran_first_name, hearing.veteran_last_name)} `}
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

  render() {

    const { worksheet, hearings } = this.props;

    const docketNotLoaded = _.isEmpty(hearings);

    const currentHearing = docketNotLoaded ? {} : hearings[worksheet.external_id];

    const readerLink = `/reader/appeal/${worksheet.appeal_external_id}/documents?category=case_summary`;

    return <span className="worksheet-header" {...headerSelectionStyling}>
      <div className="cf-push-left" {...containerStyling}>
        <div {...selectVeteranStyling}>
          <SearchableDropdown
            label="Select Veteran"
            name="worksheet-veteran-selection"
            placeholder={docketNotLoaded ? <SmallLoader spinnerColor={LOGO_COLORS.HEARINGS.ACCENT}
              message="Loading..." /> : ''}
            options={this.getDocketVeteranOptions(hearings)}
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
          href={readerLink}
          button="primary"
          target="_blank">
        Review claims folder</Link>
      </div>
    </span>;
  }
}

WorksheetHeaderVeteranSelection.propTypes = {
  getHearingDayHearings: PropTypes.func,
  hearings: PropTypes.object,
  history: PropTypes.shape({
    push: PropTypes.func
  }),
  setPrepped: PropTypes.func,
  worksheet: PropTypes.shape({
    appeal_external_id: PropTypes.string,
    external_id: PropTypes.string,
    hearing_day_id: PropTypes.number
  })
};

const mapStateToProps = (state) => ({
  hearings: state.hearingWorksheet.hearings,
  worksheet: state.hearingWorksheet.worksheet
});

const mapDispatchToProps = (dispatch) => ({
  ...bindActionCreators({
    setPrepped,
    getHearingDayHearings
  }, dispatch)
});

export default withRouter(connect(
  mapStateToProps,
  mapDispatchToProps
)(WorksheetHeaderVeteranSelection));
