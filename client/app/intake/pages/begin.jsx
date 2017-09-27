import React from 'react';
// import Link from '../../components/Link';
import SearchBar from '../../components/SearchBar';

export default class First extends React.PureComponent {

  clickButton() {
    this.props.history.push('/second');
  }

  render() {
    return <div>
      <h1>Welcome to Caseflow Intake!</h1>
      <p>To begin processing this opt-in request, please enter the Veteran ID below.</p>
      <SearchBar size="small" />
      {/* <Link to="/second">Second link</Link>
      <button onClick={this.clickButton.bind(this)}>Go</button> */}
    </div>;
  }
}


