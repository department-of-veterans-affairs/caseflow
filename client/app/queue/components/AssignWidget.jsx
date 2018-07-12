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
  setSelectedAssignee,
  setSelectedAssigneeSecondary
} from '../uiReducer/uiActions';
import {
  initialAssignTasksToUser
} from '../QueueActions';
import SearchableDropdown from '../../components/SearchableDropdown';
import Button from '../../components/Button';
import _ from 'lodash';
import type {
  AttorneysOfJudge, IsTaskAssignedToUserSelected, Task, Tasks, UiStateError, State, Attorneys
} from '../types';
import Alert from '../../components/Alert';
import pluralize from 'pluralize';
import COPY from '../../../COPY.json';
import { sprintf } from 'sprintf-js';

const OTHER = 'OTHER';

type Props = {|
  // Parameters
  previousAssigneeId: string,
  onTaskAssignment: Function,
  // From state
  attorneysOfJudge: AttorneysOfJudge,
  selectedAssignee: string,
  selectedAssigneeSecondary: string,
  isTaskAssignedToUserSelected: IsTaskAssignedToUserSelected,
  tasks: Tasks,
  error: ?UiStateError,
  success: string,
  attorneys: Attorneys,
  // Action creators
  setSelectedAssignee: Function,
  setSelectedAssigneeSecondary: Function,
  initialAssignTasksToUser: Function,
  showErrorMessage: (UiStateError) => void,
  resetErrorMessages: Function,
  showSuccessMessage: (string) => void,
  resetSuccessMessages: Function
|};

class AssignWidget extends React.PureComponent<Props> {
  selectedTasks = (): Array<Task> => {
    return _.flatMap(
      this.props.isTaskAssignedToUserSelected[this.props.previousAssigneeId] || {},
      (selected, id) => (selected ? [this.props.tasks[id]] : []));
  }

  handleButtonClick = () => {
    const { selectedAssignee, selectedAssigneeSecondary } = this.props;
    const selectedTasks = this.selectedTasks();

    this.props.resetSuccessMessages();
    this.props.resetErrorMessages();

    if (!selectedAssignee) {
      this.props.showErrorMessage(
        { title: COPY.ASSIGN_WIDGET_NO_ASSIGNEE_TITLE,
          detail: COPY.ASSIGN_WIDGET_NO_ASSIGNEE_DETAIL });

      return;
    }

    if (selectedTasks.length === 0) {
      this.props.showErrorMessage(
        { title: COPY.ASSIGN_WIDGET_NO_TASK_TITLE,
          detail: COPY.ASSIGN_WIDGET_NO_TASK_DETAIL });

      return;
    }

    if (selectedAssignee !== OTHER) {
      this.assignTasks(selectedTasks, selectedAssignee);

      return;
    }

    if (!selectedAssigneeSecondary) {
      this.props.showErrorMessage(
        { title: COPY.ASSIGN_WIDGET_NO_ASSIGNEE_TITLE,
          detail: COPY.ASSIGN_WIDGET_NO_ASSIGNEE_DETAIL });

      return;
    }

    this.assignTasks(selectedTasks, selectedAssigneeSecondary);
  }

  assignTasks = (selectedTasks: Array<Task>, assigneeId: string) => {
    const { previousAssigneeId } = this.props;

    this.props.onTaskAssignment(
      { tasks: selectedTasks,
        assigneeId,
        previousAssigneeId }).
      then(() => this.props.showSuccessMessage(
        sprintf(
          COPY.ASSIGN_WIDGET_SUCCESS,
          { numCases: selectedTasks.length,
            casePlural: pluralize('case', selectedTasks.length) }))).
      catch(() => this.props.showErrorMessage(
        { title: COPY.ASSIGN_WIDGET_ASSIGNMENT_ERROR_TITLE,
          detail: COPY.ASSIGN_WIDGET_ASSIGNMENT_ERROR_DETAIL }));
  }

  render = () => {
    const { attorneysOfJudge, selectedAssignee, selectedAssigneeSecondary, error, success, attorneys } = this.props;
    const selectedTasks = this.selectedTasks();
    const optionFromAttorney = (attorney) => ({ label: attorney.full_name,
      value: attorney.id.toString() });
    const options = attorneysOfJudge.map(optionFromAttorney).concat({ label: COPY.ASSIGN_WIDGET_OTHER,
      value: OTHER });
    const selectedOption = _.find(options, (option) => option.value === selectedAssignee);
    let optionsOther = [];
    let placeholderOther = COPY.ASSIGN_WIDGET_LOADING;
    let selectedOptionOther = null;

    if (attorneys.data) {
      optionsOther = attorneys.data.map(optionFromAttorney);
      placeholderOther = COPY.ASSIGN_WIDGET_DROPDOWN_PLACEHOLDER;
      selectedOptionOther = _.find(optionsOther, (option) => option.value === selectedAssigneeSecondary);
    }

    if (attorneys.error) {
      placeholderOther = COPY.ASSIGN_WIDGET_ERROR_LOADING_ATTORNEYS;
    }

    return <React.Fragment>
      {error && <Alert type="error" title={error.title} message={error.detail} />}
      {success && <Alert type="success" title={success} />}
      <div {...css({
        display: 'flex',
        alignItems: 'center',
        flexWrap: 'wrap',
        '& > *': { marginRight: '1rem' } })}>
        <p>{COPY.ASSIGN_WIDGET_DROPDOWN_PRIMARY_LABEL}</p>
        <SearchableDropdown
          name={COPY.ASSIGN_WIDGET_DROPDOWN_NAME_PRIMARY}
          hideLabel
          searchable
          options={options}
          placeholder={COPY.ASSIGN_WIDGET_DROPDOWN_PLACEHOLDER}
          onChange={(option) => this.props.setSelectedAssignee({ assigneeId: option.value })}
          value={selectedOption}
          styling={css({ width: '30rem' })} />
        {selectedAssignee === OTHER &&
          <React.Fragment>
            <p>{COPY.ASSIGN_WIDGET_DROPDOWN_SECONDARY_LABEL}</p>
            <SearchableDropdown
              name={COPY.ASSIGN_WIDGET_DROPDOWN_NAME_SECONDARY}
              hideLabel
              searchable
              options={optionsOther}
              placeholder={placeholderOther}
              onChange={(option) => this.props.setSelectedAssigneeSecondary({ assigneeId: option.value })}
              value={selectedOptionOther}
              styling={css({ width: '30rem' })} />
          </React.Fragment>}
        <Button
          onClick={this.handleButtonClick}
          name={sprintf(
            COPY.ASSIGN_WIDGET_BUTTON_TEXT,
            { numCases: selectedTasks.length,
              casePlural: pluralize('case', selectedTasks.length) })}
          loading={false}
          loadingText={COPY.ASSIGN_WIDGET_LOADING} />
      </div>
    </React.Fragment>;
  }
}

const mapStateToProps = (state: State) => {
  const { attorneysOfJudge, isTaskAssignedToUserSelected, tasks, attorneys } = state.queue;
  const { selectedAssignee, selectedAssigneeSecondary, messages: { error, success } } = state.ui;

  return {
    attorneysOfJudge,
    selectedAssignee,
    selectedAssigneeSecondary,
    isTaskAssignedToUserSelected,
    tasks,
    error,
    success,
    attorneys
  };
};

export default connect(
  mapStateToProps,
  (dispatch) => bindActionCreators({
    setSelectedAssignee,
    setSelectedAssigneeSecondary,
    initialAssignTasksToUser,
    showErrorMessage,
    resetErrorMessages,
    showSuccessMessage,
    resetSuccessMessages
  }, dispatch)
)(AssignWidget);
