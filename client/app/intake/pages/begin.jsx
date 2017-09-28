import React from 'react';
import SearchBar from '../../components/SearchBar';

export default class First extends React.PureComponent {
  render() {
    return <div>
      <h1>Welcome to Caseflow Intake!</h1>
      <p>To begin processing this opt-in request, please enter the Veteran ID below.</p>
      <SearchBar size="small" />
    </div>;
  }
}


