import React from 'react';
import SearchBar from '../../components/SearchBar';
import Alert from '../../components/Alert';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { doFileNumberSearch, setFileNumberSearch } from '../redux/actions';
import { REQUEST_STATE } from '../constants';

class Begin extends React.PureComponent {
  handleSearchSubmit = () => {
    this.props.doFileNumberSearch(this.props.fileNumberSearchInput).
      then(() => this.props.history.push('/review-request'));
  }

  render() {
    let searchError = this.props.searchError;

    return <div>
      { searchError &&
        <div>
          <Alert title={searchError.title} type="error">
            {searchError.body}
          </Alert>
          <p></p>
        </div>
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
  ({ searchError, inputs, requestStatus }) => ({
    fileNumberSearchInput: inputs.fileNumberSearch,
    fileNumberSearchRequestStatus: requestStatus.fileNumberSearch,
    searchError
  }),
  (dispatch) => bindActionCreators({
    doFileNumberSearch,
    setFileNumberSearch
  }, dispatch)
)(Begin);
