// @flow
import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { css } from 'glamor';
import {
  resetErrorMessages,
  showErrorMessage,
  showSuccessMessage,
  resetSuccessMessages,
  setSelectedAssignee
} from '../uiReducer/uiActions';
import {
  initialAssignTasksToUser
} from '../QueueActions';
import SearchableDropdown from '../../components/SearchableDropdown';
import Button from '../../components/Button';
import _ from 'lodash';
import type {
  AttorneysOfJudge, IsTaskAssignedToUserSelected, Tasks, UiStateError, State, AllAttorneys
} from '../types';
import Alert from '../../components/Alert';
import pluralize from 'pluralize';
import { ASSIGN_WIDGET_OTHER } from '../../../COPY.json';

const OTHER = 'OTHER';

type Props = {|
  // Parameters
  previousAssigneeId: string,
  onTaskAssignment: Function,
  // From state
  attorneysOfJudge: AttorneysOfJudge,
  selectedAssignee: string,
  isTaskAssignedToUserSelected: IsTaskAssignedToUserSelected,
  tasks: Tasks,
  error: ?UiStateError,
  success: string,
  allAttorneys: AllAttorneys,
  // Action creators
  setSelectedAssignee: Function,
  initialAssignTasksToUser: Function,
  showErrorMessage: (UiStateError) => void,
  resetErrorMessages: Function,
  showSuccessMessage: (string) => void,
  resetSuccessMessages: Function
|};

class AssignWidget extends React.PureComponent<Props> {
  selectedTasks = () => {
    return _.flatMap(
      this.props.isTaskAssignedToUserSelected[this.props.previousAssigneeId] || {},
      (selected, id) => (selected ? [this.props.tasks[id]] : []));
  }

  handleButtonClick = () => {
    const { previousAssigneeId, selectedAssignee } = this.props;
    const selectedTasks = this.selectedTasks();

    this.props.resetSuccessMessages();
    this.props.resetErrorMessages();

    if (!selectedAssignee) {
      this.props.showErrorMessage(
        { title: 'No assignee selected',
          detail: 'Please select someone to assign the tasks to.' });

      return;
    }

    if (selectedTasks.length === 0) {
      this.props.showErrorMessage(
        { title: 'No tasks selected',
          detail: 'Please select a task.' });

      return;
    }

    this.props.onTaskAssignment(
      { tasks: selectedTasks,
        assigneeId: selectedAssignee,
        previousAssigneeId }).
      then(() => this.props.showSuccessMessage(
        `Assigned ${selectedTasks.length} ${pluralize('case', selectedTasks.length)}`)).
      catch(() => this.props.showErrorMessage(
        { title: 'Error assigning tasks',
          detail: 'One or more tasks couldn\'t be assigned.' }));
  }

  render = () => {
    const optionFromAttorney = (attorney) => ({ label: attorney.full_name,
      value: attorney.id.toString() });
    const handleChange = (option) => this.props.setSelectedAssignee({ assigneeId: option.value });

    const { attorneysOfJudge, selectedAssignee, error, success, allAttorneys } = this.props;
    const options = attorneysOfJudge.map(optionFromAttorney).concat({ label: ASSIGN_WIDGET_OTHER, value: OTHER});
    const selectedOption = _.find(options, (option) => option.value === selectedAssignee);
    const showOtherSearchBox = selectedAssignee === OTHER;
    let optionsOther = [];
    let placeholderOther = 'Loading';
    let selectedOptionOther = null;
    if (allAttorneys.data) {
      optionsOther = allAttorneys.data.map(optionFromAttorney);
      placeholderOther = 'Select a user';
      selectedOptionOther = _.find(optionsOther, (option) => option.value === selectedAssignee);
    }

    return <React.Fragment>
      {error && <Alert type="error" title={error.title} message={error.detail} />}
      {success && <Alert type="success" title={success} />}
      <div {...css({
        display: 'flex',
        alignItems: 'center',
        flexWrap: 'wrap',
        '& > *': { marginRight: '1rem' } })}>
        <p>Assign to:&nbsp;</p>
        <SearchableDropdown
          name="Assignee"
          hideLabel
          searchable
          options={options}
          placeholder="Select a user"
          onChange={handleChange}
          value={selectedOption}
          styling={css({ width: '30rem' })} />
        {showOtherSearchBox &&
          <React.Fragment>
            <p>Enter the name of an attorney or judge:</p>
            <SearchableDropdown
              name="Other assignee"
              hideLabel
              searchable
              options={optionsOther}
              placeholder={placeholderOther}
              onChange={handleChange}
              value={selectedOptionOther}
              styling={css({ width: '30rem' })} />
          </React.Fragment>}
        <Button
          onClick={this.handleButtonClick}
          name={`Assign ${this.selectedTasks().length} ${pluralize('case', this.selectedTasks().length)}`}
          loading={false}
          loadingText="Loading" />
      </div>
    </React.Fragment>;
  }
}

const mapStateToProps = (state: State) => {
  const { attorneysOfJudge, isTaskAssignedToUserSelected, tasks, allAttorneys } = state.queue;
  const { selectedAssignee, messages: { error, success } } = state.ui;

  return {
    attorneysOfJudge,
    selectedAssignee,
    isTaskAssignedToUserSelected,
    tasks,
    error,
    success,
    allAttorneys
  };
};

export default connect(
  mapStateToProps,
  (dispatch) => bindActionCreators({
    setSelectedAssignee,
    initialAssignTasksToUser,
    showErrorMessage,
    resetErrorMessages,
    showSuccessMessage,
    resetSuccessMessages
  }, dispatch)
)(AssignWidget);
