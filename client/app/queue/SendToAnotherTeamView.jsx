// @flow
import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { withRouter } from 'react-router-dom';
import classNames from 'classnames';
import { css } from 'glamor';
import { sprintf } from 'sprintf-js';

import COPY from '../../COPY.json';
import CO_LOCATED_ADMIN_ACTIONS from '../../constants/CO_LOCATED_ADMIN_ACTIONS.json';
import CO_LOCATED_TEAMS from '../../constants/CO_LOCATED_TEAMS.json';

import { prepareTasksForStore } from './utils';
import {
  getTasksForAppeal,
  appealWithDetailSelector
} from './selectors';
import {
  requestSave,
  showSuccessMessage
} from './uiReducer/uiActions';
import { setTaskAttrs } from './QueueActions';

import decisionViewBase from './components/DecisionViewBase';
import SearchableDropdown from '../components/SearchableDropdown';
import Alert from '../components/Alert';

import {
  fullWidth,
  marginBottom,
  marginTop
} from './constants';

import type { State, UiStateMessage } from './types/state';
import type { Task, Appeal } from './types/models';

type ViewState = {|
  team: string
|};

type Params = {|
  appealId: string
|};

type Props = Params & {|
  task: Task,
  appeal: Appeal,
  error: ?UiStateMessage,
  highlightFormItems: boolean,
  requestSave: typeof requestSave,
  setTaskAttrs: typeof setTaskAttrs,
  showSuccessMessage: typeof showSuccessMessage
|};

class SendToAnotherTeamView extends React.Component<Props, ViewState> {
  constructor(props) {
    super(props);

    this.state = {
      team: ''
    };
  }

  validateForm = () => Object.keys(CO_LOCATED_TEAMS).includes(this.state.team);

  goToNextStep = () => {
    const {
      task,
      appeal
    } = this.props;
    const payload = {
      data: {
        task: {
          action: this.state.team
        }
      }
    };
    const successMsg = {
      title: sprintf(
        COPY.COLOCATED_ACTION_SEND_TO_ANOTHER_TEAM_CONFIRMATION,
        appeal.veteranFullName, CO_LOCATED_TEAMS[this.state.team]
      )
    };

    this.props.requestSave(`/tasks/${task.taskId}`, payload, successMsg, 'patch').
      then((resp) => {
        const response = JSON.parse(resp.text);
        const preparedTasks = prepareTasksForStore(response.tasks.data);

        this.props.setTaskAttrs(task.externalAppealId, preparedTasks[task.externalAppealId]);
      });
  }

  render = () => {
    const {
      task,
      error,
      appeal,
      highlightFormItems
    } = this.props;
    const columnStyling = css({
      width: '50%',
      maxWidth: '25rem'
    });
    const errorClass = classNames({
      'usa-input-error': highlightFormItems && !this.state.team
    });

    return <React.Fragment>
      <h1 className="cf-push-left" {...css(fullWidth, marginBottom(1))}>
        {COPY.COLOCATED_ACTION_SEND_TO_ANOTHER_TEAM_HEAD}
      </h1>
      <div {...fullWidth}>
        <span {...css(columnStyling, { float: 'left' })}>
          <strong>Veteran ID:</strong> {appeal.veteranFileNumber}
        </span>
        <span {...columnStyling}>
          <strong>Task:</strong> {CO_LOCATED_ADMIN_ACTIONS[task.action]}
        </span>
      </div>
      <hr />
      {error && <Alert type="error" title={error.title} message={error.detail} />}
      <h4 {...marginTop(3)}>{COPY.COLOCATED_ACTION_SEND_TO_ANOTHER_TEAM_SUBHEAD}</h4>
      <p {...css({ maxWidth: '70rem' }, marginTop(1), marginBottom(1))}>
        {COPY.COLOCATED_ACTION_SEND_TO_ANOTHER_TEAM_COPY}
      </p>
      <div className={errorClass} {...marginTop(1)}>
        <SearchableDropdown
          name="Select a team"
          hideLabel
          errorMessage={highlightFormItems && !this.state.team ? 'Choose one' : null}
          placeholder="Select a team"
          value={this.state.team}
          onChange={({ value }) => this.setState({ team: value })}
          options={Object.keys(CO_LOCATED_TEAMS).map((value) => ({
            label: CO_LOCATED_TEAMS[value],
            value
          }))} />
      </div>
    </React.Fragment>;
  }
}

const mapStateToProps = (state: State, ownProps: Params) => {
  const {
    highlightFormItems,
    messages: { error }
  } = state.ui;

  return {
    error,
    highlightFormItems,
    task: getTasksForAppeal(state, ownProps)[0],
    appeal: appealWithDetailSelector(state, ownProps)
  };
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  requestSave,
  setTaskAttrs,
  showSuccessMessage
}, dispatch);

const WrappedComponent = decisionViewBase(SendToAnotherTeamView, {
  hideCancelButton: true,
  continueBtnText: 'Send action'
});

export default (withRouter(
  connect(mapStateToProps, mapDispatchToProps)(WrappedComponent)
): React.ComponentType<Params>);
