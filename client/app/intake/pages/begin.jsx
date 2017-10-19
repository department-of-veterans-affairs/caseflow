import React from 'react';
import SearchBar from '../../components/SearchBar';
import Alert from '../../components/Alert';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { Redirect } from 'react-router-dom';
import { doFileNumberSearch, setFileNumberSearch } from '../redux/actions';
import { REQUEST_STATE, PAGE_PATHS, RAMP_INTAKE_STATES } from '../constants';
import { getRampElectionStatus } from '../redux/selectors';

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
    body: <div>
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
    </div>
  },
  default: {
    title: 'Something went wrong',
    body: 'Please try again. If the problem persists, please contact Caseflow support.'
  }
};

class Begin extends React.PureComponent {
  handleSearchSubmit = () => this.props.doFileNumberSearch(this.props.fileNumberSearchInput)

  getSearchErrorAlert = (searchErrorCode) => {
    const error = searchErrors[searchErrorCode] || searchErrors.default;

    return <Alert title={error.title} type="error" lowerMargin>
      { error.body }
    </Alert>;
  }

  render() {
    const {
      searchErrorCode,
      rampElectionStatus
    } = this.props;

    switch (rampElectionStatus) {
    case RAMP_INTAKE_STATES.STARTED:
      return <Redirect to={PAGE_PATHS.REVIEW}/>;
    case RAMP_INTAKE_STATES.REVIEWED:
      return <Redirect to={PAGE_PATHS.FINISH}/>;
    case RAMP_INTAKE_STATES.COMPLETED:
      return <Redirect to={PAGE_PATHS.COMPLETED}/>;
    default:
    }

    return <div>
      { searchErrorCode && this.getSearchErrorAlert(searchErrorCode) }

      <h1>Welcome to Caseflow Intake!</h1>
      <p>To begin processing this opt-in request, please enter the Veteran ID below.</p>

      <SearchBar
        size="small"
        onSubmit={this.handleSearchSubmit}
        onChange={this.props.setFileNumberSearch}
        value={this.props.fileNumberSearchInput}
        loading={this.props.fileNumberSearchRequestStatus === REQUEST_STATE.IN_PROGRESS}
        />
    </div>;
  }
}

export default connect(
  (state) => ({
    fileNumberSearchInput: state.inputs.fileNumberSearch,
    fileNumberSearchRequestStatus: state.requestStatus.fileNumberSearch,
    rampElectionStatus: getRampElectionStatus(state),
    searchErrorCode: state.searchErrorCode
  }),
  (dispatch) => bindActionCreators({
    doFileNumberSearch,
    setFileNumberSearch
  }, dispatch)
)(Begin);
