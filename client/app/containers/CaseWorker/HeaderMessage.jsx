import React from 'react';

export default class HeaderMessage extends React.PureComponent {
  render() {
    const {
      availableTasks,
      tasksRemaining
    } = this.props;

    if (tasksRemaining && !availableTasks) {
      return <div>
        <h2>All claims in queue completed</h2>
        <p>There are no more claims to pick up. Please come back later.</p>
      </div>;
    }

    if (tasksRemaining && availableTasks) {
      return <div>
        <h2>Get Started!</h2>
        <p>There are claims ready to get picked up for today.</p>
      </div>;
    }

    return <span>
      <h2>Way to go!</h2>
      <p> You have completed all the claims assigned to you.</p>
      <p>  💪💻🇺🇸</p>
    </span>;
  }
}
