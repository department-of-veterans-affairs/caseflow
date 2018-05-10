import React from 'react';
import SearchBar from '../../components/SearchBar';
import Alert from '../../components/Alert';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { Redirect } from 'react-router-dom';
import { doFileNumberSearch, setFileNumberSearch } from '../actions/common';
import { REQUEST_STATE, PAGE_PATHS, INTAKE_STATES, FORM_TYPES } from '../constants';
import { getIntakeStatus } from '../selectors';
import _ from 'lodash';

const rampIneligibleInstructions = <div>
  <p>
    Please check the Veteran ID entered, and if the Veteran ID is correct,
    take the following actions outside Caseflow:
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
        body: 'It looks like you do not have the necessary level of access to view this information.' +
          ' Please alert your manager so they can assign the form to someone else.'
      },
      veteran_not_valid: {
        title: 'The Veteran\'s profile is missing information required to create an EP.',
        body: 'Please fill in the following field(s) in the Veteran\'s profile in VBMS or the corporate database,' +
          ` then retry establishing the EP in Caseflow: ${searchErrorData.veteranMissingFields}.`
      },
      did_not_receive_ramp_election: {
        title: 'A RAMP Opt-in Notice Letter was not sent to this Veteran.',
        body: rampIneligibleInstructions
      },
      ramp_election_already_complete: {
        title: 'Opt-in already processed in Caseflow',
        body: `A RAMP opt-in with the receipt date ${searchErrorData.duplicateReceiptDate}` +
          ' was already processed in Caseflow.' +
          ' Caseflow does not currently support more than one RAMP Election for a Veteran.'
      },
      no_active_appeals: {
        title: 'Ineligible to participate in RAMP: no active appeals',
        body: rampIneligibleInstructions
      },
      no_eligible_appeals: {
        title: 'Ineligible to participate in RAMP: appeal is at the Board',
        body: rampIneligibleInstructions
      },
      no_active_compensation_appeals: {
        title: 'Ineligible to participate in RAMP: appeal does not contain any compensation issues',
        body: rampIneligibleInstructions
      },
      no_active_fully_compensation_appeals: {
        title: 'Ineligible to participate in RAMP: appeal contains non-compensation issues',
        body: 'Caseflow temporarily does not support closing appeals with any non-compensation issues.' +
          'Please contact Caseflow Support on how to proceed.'
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
      duplicate_intake_in_progress: {
        title: `${searchErrorData.duplicateProcessedBy} already started processing this form`,
        body: `We noticed that ${searchErrorData.duplicateProcessedBy} may be in the middle of ` +
         'processing the same form for this Veteran in Caseflow. Please confirm they will ' +
         'complete this intake, then move on to the next mail item.'
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

    const selectedForm = _.find(FORM_TYPES, { key: formType });

    if (!formType) {
      return <Redirect to={PAGE_PATHS.BEGIN} />;
    }

    switch (intakeStatus) {
    case INTAKE_STATES.STARTED:
      return <Redirect to={PAGE_PATHS.REVIEW} />;
    case INTAKE_STATES.REVIEWED:
      return <Redirect to={PAGE_PATHS.FINISH} />;
    case INTAKE_STATES.COMPLETED:
      return <Redirect to={PAGE_PATHS.COMPLETED} />;
    default:
    }

    return <div>
      { searchErrorCode && this.getSearchErrorAlert(searchErrorCode, searchErrorData) }

      <h1>Search for Veteran by ID</h1>
      <p>
        Enter the Veteran's ID below to process this {selectedForm.name}.
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
