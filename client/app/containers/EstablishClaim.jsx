import React, { PropTypes } from 'react';

export default class EstablishClaim extends React.Component {
  render() {
    let { task } = this.props;
    let { user, appeal } = task;

    return (
      <div className="test">
         <h1>Dispatch Show WIP</h1>
         <p>Type: {task.type}</p>
         <p>user: {user.display_name}</p>
         <p>vacols_id: {appeal.vacols_id}</p>
      </div>
    );
  }
}
