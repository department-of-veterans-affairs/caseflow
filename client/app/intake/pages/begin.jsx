import React from 'react';
import SearchBar from '../../components/SearchBar';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import {setVeteran} from '../redux/actions';

class Begin extends React.PureComponent {
  handleSearchSubmit = () => {
    this.props.setVeteran('Joe Snuffy', '2222222222')
    this.props.history.push('/review-request')
  }

  render() {
    return <div>
      <h1>Welcome to Caseflow Intake!</h1>
      <p>To begin processing this opt-in request, please enter the Veteran ID below.</p>
      <SearchBar size="small" onSubmit={this.handleSearchSubmit} />
    </div>;
  }
}

export default connect(
  null, 
  (dispatch) => bindActionCreators({setVeteran}, dispatch)
)(Begin)
