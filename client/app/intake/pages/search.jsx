import React from 'react';
import SearchBar from '../../components/SearchBar';
import Alert from '../../components/Alert';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { Redirect } from 'react-router-dom';
import { doFileNumberSearch, setFileNumberSearch } from '../actions/common';
import { REQUEST_STATE, PAGE_PATHS, RAMP_INTAKE_STATES } from '../constants';
import { getIntakeStatus } from '../selectors';

const rampIneligibleInstructions = <div>
  <p>
    Please check the Veteran ID entered, and if the Veteran ID
    is correct, take the following actions outside Caseflow:
  </p>
  <ul>
    <li>
      Upload the RAMP Election to the VBMS eFolder with
      Document Type <b>Correspondence</b> and Subject Line "RAMP Election".
    </li>
    <li>
      Notify the Veteran by mail of his/her ineligibility to participate
      in RAMP using the <b>RAMP Ineligible Letter</b> in <em>Letter Creator</em>.
    </li>
    <li>
      Document your actions as a permanent note in VBMS.
    </li>
  </ul>
</div>;

class Search extends React.PureComponent {
  handleSearchSubmit = () => (
    this.props.doFileNumberSearch(this.props.formType, this.props.fileNumberSearchInput)
  )

  clearSearch = () => this.props.setFileNumberSearch('')

  getSearchErrorAlert = (searchErrorCode, searchErrorData) => {
    // The values in this switch statement need to be snake_case
    // because they're being matched to server response values.
    const searchErrors = {
      invalid_file_number: {
        title: 'Veteran ID not found',
        body: 'Please enter a valid Veteran ID and try again.'
      },
      veteran_not_found: {
        title: 'Veteran ID not found',
        body: 'Please enter a valid Veteran ID and try again.'
      },
      veteran_not_accessible: {
        title: 'You don\'t have permission to view this veteran\'s information​',
        body: 'Please enter a valid Veteran ID and try again.'
      },
      did_not_receive_ramp_election: {
        title: 'A RAMP Opt-in Notice Letter was not sent to this Veteran.',
        body: rampIneligibleInstructions
      },
      ramp_election_already_complete: {
        title: 'Opt-in already processed in Caseflow',
        body: `A RAMP opt-in with the notice date ${searchErrorData.duplicateNoticeDate}` +
          ' was already processed in Caseflow. Please ensure this' +
          ' is a duplicate election form, and proceed to the next intake.'
      },
      no_active_appeals: {
        title: 'Ineligible to participate in RAMP: no active appeals',
        body: rampIneligibleInstructions
      },
      no_eligible_appeals: {
        title: 'Ineligible to participate in RAMP: appeal is at the Board',
        body: rampIneligibleInstructions
      },
      no_complete_ramp_election: {
        title: 'No RAMP Opt-In Election',
        body: 'A RAMP Opt-In Election Form was not yet processed in Caseflow, so this Veteran' +
          ' is not eligible to request a RAMP re-filing. Notify the Veteran using the' +
          ' “RAMP Ineligible Letter”.'
      },
      ramp_election_is_active: {
        title: 'This Veteran has a pending RAMP EP in VBMS',
        body: 'If this Veteran has not yet received a RAMP decision on their RAMP Opt-In' +
          ' Election Form, notify them using the “RAMP Ineligible Letter” (premature election).'
      },
      ramp_election_no_issues: {
        title: 'This Veteran has a pending RAMP EP with no contentions',
        body: 'Please ensure contentions were added to the original RAMP Election EP'
      },
      ramp_refiling_already_processed: {
        title: 'Selection Form already processed in Caseflow',
        body: 'Caseflow does not currently support more than one Selection Form for a Veteran.' +
         'Please contact Caseflow Support if you need additional assistance.'
      },
      default: {
        title: 'Something went wrong',
        body: 'Please try again. If the problem persists, please contact Caseflow support.'
      }
    };

    const error = searchErrors[searchErrorCode] || searchErrors.default;

    return <Alert title={error.title} type="error" lowerMargin>
      { error.body }
    </Alert>;
  }

  render() {
    const {
      searchErrorCode,
      searchErrorData,
      intakeStatus,
      formType
    } = this.props;

    if (!formType) {
      return <Redirect to={PAGE_PATHS.BEGIN} />;
    }

    switch (intakeStatus) {
    case RAMP_INTAKE_STATES.STARTED:
      return <Redirect to={PAGE_PATHS.REVIEW} />;
    case RAMP_INTAKE_STATES.REVIEWED:
      return <Redirect to={PAGE_PATHS.FINISH} />;
    case RAMP_INTAKE_STATES.COMPLETED:
      return <Redirect to={PAGE_PATHS.COMPLETED} />;
    default:
    }

    return <div>
      { searchErrorCode && this.getSearchErrorAlert(searchErrorCode, searchErrorData) }

      <h1>Search for Veteran by ID</h1>
      <p>
        To continue processing this form,
        enter the Veteran’s 8 or 9 digit ID number into the search bar below.
      </p>

      <SearchBar
        size="small"
        onSubmit={this.handleSearchSubmit}
        onChange={this.props.setFileNumberSearch}
        onClearSearch={this.clearSearch}
        value={this.props.fileNumberSearchInput}
        loading={this.props.fileNumberSearchRequestStatus === REQUEST_STATE.IN_PROGRESS}
        submitUsingEnterKey
      />
    </div>;
  }
}

export default connect(
  (state) => ({
    intakeStatus: getIntakeStatus(state),
    fileNumberSearchInput: state.intake.fileNumberSearch,
    fileNumberSearchRequestStatus: state.intake.requestStatus.fileNumberSearch,
    searchErrorCode: state.intake.searchErrorCode,
    searchErrorData: state.intake.searchErrorData,
    formType: state.intake.formType
  }),
  (dispatch) => bindActionCreators({
    doFileNumberSearch,
    setFileNumberSearch
  }, dispatch)
)(Search);
