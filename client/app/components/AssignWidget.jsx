import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { css } from 'glamor';
import {
  resetErrorMessages,
  showErrorMessage
} from '../queue/uiReducer/uiActions';
import {
  setSelectedAssigneeOfUser,
  initialAssignTasksToUser
} from '../queue/QueueActions';
import SearchableDropdown from '../components/SearchableDropdown';
import Button from '../components/Button';
import _ from 'lodash';

class AssignWidget extends React.PureComponent {
  appealIdsOfSelectedTasks = () => {
    return _.flatMap(
      this.props.isTaskAssignedToUserSelected[this.props.userId] || [],
      (selected, id) => (selected ? [this.props.tasks[id].attributes.appeal_id] : []));
  }

  handleButtonClick = () => {
    const { userId, selectedAssigneeOfUser } = this.props;

    if (!selectedAssigneeOfUser[userId]) {
      this.props.showErrorMessage(
        { heading: 'No assignee selected',
          text: 'Please select someone to assign the tasks to.' });

      return;
    }

    if (this.appealIdsOfSelectedTasks().length === 0) {
      this.props.showErrorMessage(
        { heading: 'No tasks selected',
          text: 'Please select a task.' });

      return;
    }

    this.props.initialAssignTasksToUser(
      { appealIdsOfTasks: this.appealIdsOfSelectedTasks(),
        assigneeId: selectedAssigneeOfUser[userId] }).
      then(() => this.props.resetErrorMessages()).
      catch(() => this.props.showErrorMessage(
        { heading: 'Error assigning tasks',
          text: 'One or more tasks couldn\'t be assigned.' }));
  }

  render = () => {
    const { userId, attorneysOfJudge, selectedAssigneeOfUser, error } = this.props;
    const options = attorneysOfJudge.map((attorney) => ({ label: attorney.full_name,
      value: attorney.id.toString() }));
    const selectedOption =
      selectedAssigneeOfUser[userId] ?
        options.filter((option) => option.value === selectedAssigneeOfUser[userId])[0] :
        { label: 'Select a user',
          value: null };

    return <React.Fragment>
      {error &&
        <div className="usa-alert usa-alert-error" role="alert">
          <div className="usa-alert-body">
            <h3 className="usa-alert-heading">{error.heading}</h3>
            <p className="usa-alert-text">{error.text}</p>
          </div>
        </div>}
      <div {...css({ display: 'flex',
        alignItems: 'center' })}>
        <p>Assign to:&nbsp;</p>
        <SearchableDropdown
          name="Assignee"
          hideLabel
          searchable
          options={options}
          onChange={(option) => this.props.setSelectedAssigneeOfUser({ userId,
            assigneeId: option.value })}
          value={selectedOption}
          styling={css({ width: '30rem' })} />
        <p>&nbsp;</p>
        <Button
          onClick={this.handleButtonClick}
          name={`Assign ${this.appealIdsOfSelectedTasks().length} case(s)`}
          loading={false}
          loadingText="Loading" />
      </div>
    </React.Fragment>;
  }
}

export default connect(
  (state) => {
    const { attorneysOfJudge, selectedAssigneeOfUser, isTaskAssignedToUserSelected, tasks } = state.queue;
    const error = state.ui.messages.error;

    return { attorneysOfJudge,
      selectedAssigneeOfUser,
      isTaskAssignedToUserSelected,
      tasks,
      error };
  },
  (dispatch) => bindActionCreators({ setSelectedAssigneeOfUser,
    initialAssignTasksToUser,
    showErrorMessage,
    resetErrorMessages }, dispatch)
)(AssignWidget);
