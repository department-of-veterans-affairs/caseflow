// @flow
import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { withRouter } from 'react-router-dom';

import COPY from '../../COPY.json';


import {
  appealWithDetailSelector,
  tasksForAppealAssignedToUserSelector,
  incompleteOrganizationTasksByAssigneeIdSelector
} from './selectors';import { setAppealAod } from './QueueActions';

import SearchableDropdown from '../components/SearchableDropdown';
import editModalBase from './components/EditModalBase';
import { requestSave } from './uiReducer/uiActions';

import type { State } from './types/state';
import type { Appeal } from './types/models';

type Params = {|
  appealId: string
|};

type Props = Params & {|
  appeal: Appeal,
  highlightFormItems: boolean,
  requestSave: typeof requestSave,
  setAppealAod: typeof setAppealAod
|};

type ViewState = {|
  granted: ?string,
  reason: ?string
|};

class AssignToView extends React.Component<Props, ViewState> {
  constructor(props) {
    super(props);

    this.state = {
      selectedValue: null
    };
  }

  submit = () => {
    const {
      appeal,
      task,
      isTeamAssign
    } = this.props;
    const payload = {
      data: {
        tasks: [{
          type: "GenericTask",
          title: task.title,
          external_id: appeal.externalId,
          parent_id: task.taskId,
          assigned_to_id: this.state.selectedValue,
          assigned_to_type: isTeamAssign ? "Organization" : "User"
        }]
      }
    };
    const successMsg = {
      title: 'Task assigned to team'
    };

    return this.props.requestSave(`/tasks`, payload, successMsg).
      then(() => {
        console.log("success");
      });
  }

  options = () => {
    if (this.props.isTeamAssign) {
      return this.props.task.assignableOrganizations.map((organization) => {
        return {
          label: organization.name,
          value: organization.id
        }
      });
    }

    return this.props.task.assignableUsers.map((user) => {
      return {
        label: user.full_name,
        value: user.id
      }
    });
  }

  render = () => {
    const {
      highlightFormItems
    } = this.props;

    return <React.Fragment>
      <h3>Choose a team</h3>
      <SearchableDropdown
        name="Teams"
        searchable={false}
        hideLabel
        errorMessage={highlightFormItems && !this.state.granted ? 'Choose one' : null}
        placeholder={COPY.ADVANCE_ON_DOCKET_MOTION_DISPOSITION_DROPDOWN_PLACEHOLDER}
        value={this.state.selectedValue}
        onChange={(option) => this.setState({ selectedValue: option.value })}
        options={this.options()} />
    </React.Fragment>;
  }
}

const mapStateToProps = (state: State, ownProps: Params) => {
  const {
    highlightFormItems
  } = state.ui;

  return {
    highlightFormItems,
    task: tasksForAppealAssignedToUserSelector(state, { appealId: ownProps.appealId })[0] ||
      incompleteOrganizationTasksByAssigneeIdSelector(state, { appealId: ownProps.appealId })[0],
    appeal: appealWithDetailSelector(state, ownProps)
  };
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  requestSave,
  setAppealAod
}, dispatch);

export default (withRouter(connect(mapStateToProps, mapDispatchToProps)(
  editModalBase(AssignToView, COPY.ADVANCE_ON_DOCKET_MOTION_PAGE_TITLE)
)): React.ComponentType<Params>);
