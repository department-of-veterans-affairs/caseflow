import React, { PropTypes } from 'react';

export default class TasksManagerIndex extends React.Component {
  render() {
    let {
      completedCountToday,
      toCompleteCount
    } = this.props;

    return <div className="cf-app-segment cf-app-segment--alt">
      <h1>ARC Workflow
        <span className="cf-associated-header">
          {completedCountToday} out
          of {(toCompleteCount + completedCountToday)} cases completed today
        </span>
      </h1>
    </div>;
  }
}

TasksManagerIndex.propTypes = {
  completedCountToday: PropTypes.number.isRequired,
  toCompleteCount: PropTypes.number.isRequired
};
