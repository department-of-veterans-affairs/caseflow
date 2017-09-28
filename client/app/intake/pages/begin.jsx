import React from 'react';
import SearchBar from '../../components/SearchBar';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { setVeteran, setFileNumberSearch } from '../redux/actions';
import _ from 'lodash';

class Begin extends React.PureComponent {
  handleSearchSubmit = () => {
    this.props.setVeteran('Joe Snuffy', '2222222222');
    this.props.history.push('/review-request');
  }

  render() {
    return <div>
      <h1>Welcome to Caseflow Intake!</h1>
      <p>To begin processing this opt-in request, please enter the Veteran ID below.</p>
      <SearchBar size="small" onSubmit={this.handleSearchSubmit} onChange={this.props.setFileNumberSearch} />
    </div>;
  }
}

export default connect(
  ({ inputs }) => _.pick(inputs, 'fileNumberSearch'),
  (dispatch) => bindActionCreators({
    setVeteran,
    setFileNumberSearch
  }, dispatch)
)(Begin);
