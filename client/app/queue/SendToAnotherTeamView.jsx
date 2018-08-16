// @flow
import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { withRouter } from 'react-router-dom';
import { css } from 'glamor';

import COPY from '../../COPY.json';
import CO_LOCATED_ADMIN_ACTIONS from '../../constants/CO_LOCATED_ADMIN_ACTIONS.json';
import CO_LOCATED_TEAMS from '../../constants/CO_LOCATED_TEAMS.json';

import {
  getTasksForAppeal,
  appealWithDetailSelector
} from './selectors';
import { requestSave } from './uiReducer/uiActions';

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
  error: ?UiStateMessage,
  appeal: Appeal,
  task: Task,
  requestSave: typeof requestSave
|};

class SendToAnotherTeamView extends React.Component<Props, ViewState> {
  constructor(props) {
    super(props);

    this.state = {
      team: ''
    };
  }

  validateForm = () => Object.keys(CO_LOCATED_TEAMS).includes(this.state.team);

  // todo: make this a default (method) in decisionViewBase?
  getPrevStepUrl = () => `/queue/appeals/${this.props.appealId}`;

  goToNextStep = () => {
    // const payload = {};
    // const successMsg = {
    //   title: 'success',
    //   detail: ''
    // };

    return true;
    // this.props.requestSave('/tasks', payload, successMsg);
  }

  render = () => {
    const {
      task,
      error,
      appeal
    } = this.props;
    const columnStyling = css({
      width: '50%',
      maxWidth: '25rem'
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
      <p {...css({ maxWidth: '70rem' }, marginTop(1))}>
        {COPY.COLOCATED_ACTION_SEND_TO_ANOTHER_TEAM_COPY}
      </p>
      <SearchableDropdown
        name="Select a team"
        hideLabel
        placeholder="Select a team"
        value={this.state.team}
        onChange={({ value }) => this.setState({ team: value })}
        options={Object.keys(CO_LOCATED_TEAMS).map((value) => ({
          label: CO_LOCATED_TEAMS[value],
          value
        }))} />
    </React.Fragment>;
  }
}

const mapStateToProps = (state: State, ownProps: Params) => ({
  error: state.ui.messages.error,
  task: getTasksForAppeal(state, ownProps)[0],
  appeal: appealWithDetailSelector(state, ownProps)
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  requestSave
}, dispatch);

const WrappedComponent = decisionViewBase(SendToAnotherTeamView, {
  hideCancelButton: true,
  continueBtnText: 'Send action'
});

export default (withRouter(
  connect(mapStateToProps, mapDispatchToProps)(WrappedComponent)
): React.ComponentType<Params>);
