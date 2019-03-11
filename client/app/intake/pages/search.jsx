import React, { Fragment } from 'react';
import SearchBar from '../../components/SearchBar';
import Alert from '../../components/Alert';
import BareList from '../../components/BareList';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { Redirect } from 'react-router-dom';
import { doFileNumberSearch, setFileNumberSearch } from '../actions/intake';
import { PAGE_PATHS, INTAKE_STATES, REQUEST_STATE } from '../constants';
import { getIntakeStatus } from '../selectors';
import _ from 'lodash';

const steps = [
  <span>
    Upload the RAMP Election form to the VBMS eFolder with
    Document Type <b>RAMP Opt-in Election</b> and Subject Line "RAMP Election".
  </span>,
  <span>
    Notify the Veteran by mail of his/her ineligibility to participate
    in RAMP using the <b>RAMP Ineligible Letter</b> in <em>Letter Creator</em>.
  </span>,
  <span>
    Document your actions as a permanent note in VBMS.
  </span>

];

const stepFns = steps.map((step, index) =>
  () => <span><strong>Step {index + 1}.</strong> {step}</span>
);

const rampIneligibleInstructions = <div>
  <p>
    Please check the Veteran ID entered, and if the Veteran ID is correct,
    take the following actions outside Caseflow:
  </p>
  <BareList items={stepFns} />
</div>;

const veteranNotFoundInstructions = <div>
  <p>Enter a valid Veteran ID or SSN and search again.</p>
  <p>
    Note: If you are certain the Veteran ID or SSN is correct,
    the claimant may not exist in the VBA Corporate Database.
    If you have access, please add claimant to the Corporate
    Database to continue processing this intake. If you do not
    have access, please
    <b>
      <a href="mailto:VACaseflowIntake@va.gov?Subject=Add%20claimant%20to%20Corporate%20Database"> email </a>
    </b>
    for assistance.
  </p>
</div>;

const missingFieldsMessage = (fields) => <p>
  Please fill in the following field(s) in the Veteran's profile in VBMS or the corporate database,
  then retry establishing the EP in Caseflow: {fields}.
</p>;

const addressTips = [
  () => <Fragment>Do: move the last word(s) of the street address down to an another street address field</Fragment>,
  () => <Fragment>Do: abbreviate to St. Ave. Rd. Blvd. Dr. Ter. Pl. Ct.</Fragment>,
  () => <Fragment>Don't: edit street names or numbers</Fragment>
];

const addressTooLongMessage = <Fragment>
  <p>
    This Veteran's address is too long. Please edit it in VBMS or SHARE so each address field is no longer than
    20 characters (including spaces) then try again.
  </p>
  <p>Tips:</p>
  <BareList items={addressTips} ListElementComponent="ul" />
</Fragment>;

const invalidVeteranInstructions = (searchErrorData) => <Fragment>
  { (_.get(searchErrorData.veteranMissingFields, 'length', 0) > 0) &&
    missingFieldsMessage(searchErrorData.veteranMissingFields) }
  { searchErrorData.veteranAddressTooLong && addressTooLongMessage }
</Fragment>;

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
        title: 'Veteran not found',
        body: veteranNotFoundInstructions
      },
      veteran_has_multiple_phone_numbers: {
        title: 'The Veteran has multiple active phone numbers',
        body: 'Please edit the Veteran\'s contact information in SHARE to have only one active phone number.'
      },
      veteran_not_accessible: {
        title: 'You don\'t have permission to view this Veteran\'s information​',
        body: 'It looks like you do not have the necessary level of access to view this information.' +
          ' Please alert your manager so they can assign the form to someone else.'
      },
      veteran_not_valid: {
        title: 'The Veteran\'s profile has missing or invalid information required to create an EP.',
        body: invalidVeteranInstructions(searchErrorData)
      },
      did_not_receive_ramp_election: {
        title: 'A RAMP Opt-in Notice Letter was not sent to this Veteran.',
        body: rampIneligibleInstructions
      },
      no_active_appeals: {
        title: 'Ineligible to participate in RAMP: no active appeals',
        body: rampIneligibleInstructions
      },
      no_eligible_appeals: {
        title: 'Ineligible to participate in RAMP',
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
          ' “RAMP Ineligible Letter.”'
      },
      ramp_election_is_active: {
        title: 'This Veteran has a pending RAMP EP in VBMS',
        body: 'If this Veteran has not yet received a decision for their RAMP Opt-In Election,' +
          ' notify them using the “RAMP Ineligible Letter” (premature election).'
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
        body: 'Caseflow does not currently support more than one Selection Form for a Veteran. ' +
         'Please contact Caseflow Support if you need additional assistance.'
      },
      default: {
        title: 'Something went wrong',
        body: 'Please try again. If the problem persists, please contact Caseflow support.'
      }
    };

    const error = searchErrors[searchErrorCode] || searchErrors.default;

    return <Alert title={error.title} type="error">
      { error.body }
    </Alert>;
  }

  render() {
    const {
      searchErrorCode,
      searchErrorData,
      intakeStatus,
      formType,
      fileNumberSearchInput
    } = this.props;

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

      <SearchBar
        size="small"
        title="Enter the Veteran's ID or SSN"
        onSubmit={this.handleSearchSubmit}
        searchDisabled={_.isEmpty(fileNumberSearchInput)}
        onChange={this.props.setFileNumberSearch}
        onClearSearch={this.clearSearch}
        value={fileNumberSearchInput}
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
