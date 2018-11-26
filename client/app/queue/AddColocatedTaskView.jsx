// @flow
import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { css } from 'glamor';
import _ from 'lodash';
import { sprintf } from 'sprintf-js';

import decisionViewBase from './components/DecisionViewBase';
import TextareaField from '../components/TextareaField';
import SearchableDropdown from '../components/SearchableDropdown';
import Alert from '../components/Alert';

import { requestSave } from './uiReducer/uiActions';
import { onReceiveAmaTasks, setAppealAttrs } from './QueueActions';

import {
  appealWithDetailSelector,
  taskById
} from './selectors';
import {
  fullWidth,
  marginBottom,
  marginTop
} from './constants';
import COPY from '../../COPY.json';
import CO_LOCATED_ADMIN_ACTIONS from '../../constants/CO_LOCATED_ADMIN_ACTIONS.json';
import DispatchSuccessDetail from './components/DispatchSuccessDetail';

import type { Appeal, Task } from './types/models';
import type { UiStateMessage } from './types/state';

type ComponentState = {|
  label: ?string,
  instructions: string
|};

type Params = {|
  appealId: string,
  taskId: string
|};

type Props = Params & {|
  // store
  highlightFormItems: boolean,
  error: ?UiStateMessage,
  appeal: Appeal,
  task: Task,
  // dispatch
  requestSave: typeof requestSave,
  onReceiveAmaTasks: typeof onReceiveAmaTasks,
  setAppealAttrs: typeof setAppealAttrs
|};

class AddColocatedTaskView extends React.PureComponent<Props, ComponentState> {
  constructor(props) {
    super(props);

    this.state = {
      label: null,
      instructions: ''
    };
  }

  validateForm = () => Object.values(this.state).every(Boolean);

  buildPayload = () => {
    const { task, appeal } = this.props;

    return {
      ...this.state,
      type: 'ColocatedTask',
      external_id: appeal.externalId,
      parent_id: appeal.isLegacyAppeal ? null : task.taskId
    };
  }

  goToNextStep = () => {
    const { task } = this.props;
    const payload = {
      data: {
        tasks: this.buildPayload()
      }
    };
    const successMsg = {
      title: sprintf(COPY.ADD_COLOCATED_TASK_CONFIRMATION_TITLE, CO_LOCATED_ADMIN_ACTIONS[this.state.label]),
      detail: <DispatchSuccessDetail task={task} />
    };

    this.props.requestSave('/tasks', payload, successMsg).
      then((resp) => {
        if (task.isLegacy) {
          this.props.setAppealAttrs(task.externalAppealId, { location: 'CASEFLOW' });
        } else {
          const response = JSON.parse(resp.text);

          this.props.onReceiveAmaTasks(response.tasks.data);
        }
      });
  }

  render = () => {
    const { highlightFormItems, error } = this.props;
    const { label, instructions } = this.state;

    return <React.Fragment>
      <h1 className="cf-push-left" {...css(fullWidth, marginBottom(1))}>
        {COPY.ADD_COLOCATED_TASK_SUBHEAD}
      </h1>
      <hr />
      {error && <Alert title={error.title} type="error">
        {error.detail}
      </Alert>}
      <div {...marginTop(4)}>
        <SearchableDropdown
          errorMessage={highlightFormItems && !label ? COPY.FORM_ERROR_FIELD_REQUIRED : null}
          name={COPY.ADD_COLOCATED_TASK_ACTION_TYPE_LABEL}
          placeholder="Select an action type"
          options={_.map(CO_LOCATED_ADMIN_ACTIONS, (key: string, value: string) => ({
            key,
            value
          }))}
          onChange={(option) => option && this.setState({ label: option.value })}
          value={this.state.label} />
      </div>
      <div {...marginTop(4)}>
        <TextareaField
          errorMessage={highlightFormItems && !instructions ? COPY.FORM_ERROR_FIELD_REQUIRED : null}
          name={COPY.ADD_COLOCATED_TASK_INSTRUCTIONS_LABEL}
          onChange={(value) => this.setState({ instructions: value })}
          value={instructions} />
      </div>
    </React.Fragment>;
  }
}

const mapStateToProps = (state, ownProps) => ({
  highlightFormItems: state.ui.highlightFormItems,
  error: state.ui.messages.error,
  appeal: appealWithDetailSelector(state, ownProps),
  task: taskById(state, { taskId: ownProps.taskId })
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  requestSave,
  onReceiveAmaTasks,
  setAppealAttrs
}, dispatch);

const WrappedComponent = decisionViewBase(AddColocatedTaskView, {
  hideCancelButton: true,
  continueBtnText: 'Assign Action'
});

export default (connect(mapStateToProps, mapDispatchToProps)(WrappedComponent): React.ComponentType<Params>);
