/* eslint-disable react/prop-types */

import React from 'react';
import SearchBar from '../../components/SearchBar';
import Alert from '../../components/Alert';
import BareList from '../../components/BareList';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { Redirect } from 'react-router-dom';
import { doFileNumberSearch, setFileNumberSearch } from '../actions/intake';
import { invalidVeteranInstructions } from '../components/ErrorAlert';
import { PAGE_PATHS, INTAKE_STATES, REQUEST_STATE } from '../constants';
import { getIntakeStatus } from '../selectors';
import _ from 'lodash';
import COPY from '../../../COPY';

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
    {COPY.INTAKE_VETERAN_NOT_FOUND}
    <b>
      <a href="mailto:VACaseflowIntake@va.gov?Subject=Add%20claimant%20to%20Corporate%20Database"> email </a>
    </b>
    for assistance.
  </p>
</div>;

const incidentFlashTeamEmail = React.createElement(
  'a', { href: 'mailto:FRAUDINCIDENTTEAM.VBACO@va.gov ? Subject=Temporarily%20unlock%20incident%20flash' },
  'incident team'
);

const incidentFlashError = React.createElement(
  'span', { id: 'incidentFlashError' }, COPY.INCIDENT_FLASH_ERROR_START, incidentFlashTeamEmail,
  COPY.INCIDENT_FLASH_ERROR_END
);

class Search extends React.PureComponent {
  handleSearchSubmit = () => (
    this.props.doFileNumberSearch(this.props.formType, this.props.fileNumberSearchInput)
  )

  clearSearch = () => this.props.setFileNumberSearch('')

  getSearchErrorAlert = (searchErrorCode, searchErrorData) => {
    // The values in this switch statement need to be snake_case
    // because they're being matched to server response values.
    const YourITLink = <Link href="https://yourit.va.gov" target="_blank" rel="noopener noreferrer">YourIT</Link>;
    const searchErrors = {
      invalid_file_number: {
        title: 'Veteran ID not found',
        body: COPY.INTAKE_SEARCH_ERROR_INVALID_FILE_NUMBER
      },
      veteran_not_found: {
        title: 'Veteran not found',
        body: veteranNotFoundInstructions
      },
      reserved_veteran_file_number: {
        title: 'Invalid file number',
        body: COPY.INTAKE_SEARCH_ERROR_INVALID_FILE_NUMBER
      },
      veteran_has_multiple_phone_numbers: {
        title: 'The Veteran has multiple active phone numbers',
        body: COPY.DUPLICATE_PHONE_NUMBER_MESSAGE
      },
      veteran_has_duplicate_records_in_corpdb: {
        title: 'Duplicate veteran records',
        body: <React.Fragment key="alert-error-body">
          {'This Veteran has a duplicate record in the Corporate database (CorpDB). Please ' +
              'follow your locally established procedures for addressing duplicate records ' +
              'to the assigned point-of-contact of the regional office.'}
        </React.Fragment>
      },
      veteran_not_accessible: {
        title: "You don't have permission to view this Veteran's information",
        body: COPY.INTAKE_SEARCH_ERROR_NOT_ACCESSIBLE
      },
      veteran_not_modifiable: {
        title: "You don't have permission to intake this Veteran",
        body: COPY.INTAKE_SEARCH_ERROR_NOT_MODIFIABLE
      },
      veteran_not_valid: {
        title: 'Check the Veteran\'s profile for invalid information',
        body: invalidVeteranInstructions(searchErrorData)
      },
      incident_flash: {
        title: 'The Veteran has an incident flash',
        body: incidentFlashError
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
         'Please contact your management team if you need additional assistance.'
      },
      default: {
        title: 'Something went wrong',
        body: <React.Fragment key="alert-error-body">
          {'Please try again. If the problem persists, please contact the Caseflow team ' +
              'via the VA Enterprise Service Desk at 855-673-4357 or by creating a ticket via '}
          { YourITLink }
          {`. Error code ${searchErrorCode}.`}
        </React.Fragment>
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
