// @flow
import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { withRouter } from 'react-router-dom';
import DECISION_TYPES from '../../../constants/APPEAL_DECISION_TYPES.json';
import DECASS_WORK_PRODUCT_TYPES from '../../../constants/DECASS_WORK_PRODUCT_TYPES.json';

import SearchableDropdown, { type OptionType } from '../../components/SearchableDropdown';
import {
  appealWithDetailSelector,
  tasksForAppealAssignedToAttorneySelector,
  tasksForAppealAssignedToUserSelector
} from '../selectors';

import {
  stageAppeal,
  initialAssignTasksToUser,
  reassignTasksToUser
} from '../QueueActions';
import {
  dropdownStyling,
  JUDGE_DECISION_OPTIONS
} from '../constants';
import AssignWidget from './AssignWidget';
import type { Task, Appeal } from '../types/models';
import type { State } from '../types/state';

const ASSIGN = 'ASSIGN';

type Params = {|
  appealId: string
|};

type Props = Params & {|
  // From store
  appeal: Appeal,
  task: Task,
  changedAppeals: Array<string>,
  decision: Object,
  userRole: string,
  // Action creators
  stageAppeal: typeof stageAppeal,
  initialAssignTasksToUser: typeof initialAssignTasksToUser,
  reassignTasksToUser: typeof reassignTasksToUser,
  // From withRouter
  history: Object
|};

type ComponentState = {
  selectedOption: ?OptionType
};

class JudgeActionsDropdown extends React.PureComponent<Props, ComponentState> {
  constructor(props) {
    super(props);

    this.state = { selectedOption: null };
  }

  handleChange = (option) => {
    this.setState({ selectedOption: option });

    if (!option) {
      return;
    }
    if (option.value === ASSIGN) {
      return;
    }

    const {
      appeal,
      appealId,
      history
    } = this.props;
    const actionType = option.value;

    let nextPage;

    if (actionType === DECISION_TYPES.OMO_REQUEST) {
      nextPage = 'omo_request/evaluate';
    } else if (appeal.isLegacyAppeal) {
      nextPage = 'dispatch_decision/dispositions';
    } else {
      nextPage = 'dispatch_decision/special_issues';
    }

    this.props.stageAppeal(appealId);

    history.push('');
    history.replace(`/queue/appeals/${appealId}/${nextPage}`);
  }

  handleAssignment = (
    { tasks, assigneeId, previousAssigneeId }: { tasks: Array<Task>, assigneeId: string, previousAssigneeId: string}
  ) => {
    if (tasks[0].action === 'assign') {
      return this.props.initialAssignTasksToUser({
        tasks,
        assigneeId,
        previousAssigneeId
      });
    }

    return this.props.reassignTasksToUser({
      tasks,
      assigneeId,
      previousAssigneeId
    });
  }

  assignWidgetVisible = () => {
    const { selectedOption } = this.state;

    return selectedOption && selectedOption.value === ASSIGN;
  }

  render = () => {
    const {
      task
    } = this.props;
    const options = [];

    if (task.action === 'review') {
      options.push(DECASS_WORK_PRODUCT_TYPES.OMO_REQUEST.includes(task.workProduct) ?
        JUDGE_DECISION_OPTIONS.OMO_REQUEST :
        JUDGE_DECISION_OPTIONS.DRAFT_DECISION
      );
    } else {
      options.push({
        label: 'Assign to attorney',
        value: ASSIGN
      });
    }

    return <React.Fragment>
      <SearchableDropdown
        placeholder="Select an action&hellip;"
        name={`start-checkout-flow-${this.props.appealId}`}
        options={options}
        onChange={this.handleChange}
        hideLabel
        dropdownStyling={dropdownStyling}
        value={this.state.selectedOption} />
      {this.assignWidgetVisible() &&
        <AssignWidget
          onTaskAssignment={this.handleAssignment}
          previousAssigneeId={task.assignedTo.id.toString()}
          selectedTasks={[task]} />}
    </React.Fragment>;
  }
}

const mapStateToProps = (state: State, ownProps: Params) => ({
  appeal: appealWithDetailSelector(state, { appealId: ownProps.appealId }),
  task: tasksForAppealAssignedToAttorneySelector(state, ownProps)[0] ||
    tasksForAppealAssignedToUserSelector(state, ownProps)[0],
  changedAppeals: Object.keys(state.queue.stagedChanges.appeals),
  decision: state.queue.stagedChanges.taskDecision,
  userRole: state.ui.userRole
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  stageAppeal,
  initialAssignTasksToUser,
  reassignTasksToUser
}, dispatch);

export default (withRouter(
  connect(mapStateToProps, mapDispatchToProps)(JudgeActionsDropdown)
): React.ComponentType<Params>);
