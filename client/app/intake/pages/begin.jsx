import React from 'react';
import SearchBar from '../../components/SearchBar';
import Alert from '../../components/Alert';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { Redirect } from 'react-router-dom';
import { doFileNumberSearch, setFileNumberSearch } from '../redux/actions';
import { REQUEST_STATE, PAGE_PATHS, RAMP_INTAKE_STATES } from '../constants';
import { getRampElectionStatus } from '../redux/selectors';

class Begin extends React.PureComponent {
  handleSearchSubmit = () => this.props.doFileNumberSearch(this.props.fileNumberSearchInput)

  render() {
    const {
      searchError,
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
      { searchError &&
        <Alert title={searchError.title} type="error" lowerMargin>
          {searchError.body}
        </Alert>
      }

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
    searchError: state.searchError
  }),
  (dispatch) => bindActionCreators({
    doFileNumberSearch,
    setFileNumberSearch
  }, dispatch)
)(Begin);
