// @flow
import * as React from 'react';
import pluralize from 'pluralize';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { css } from 'glamor';
import _ from 'lodash';
import { sprintf } from 'sprintf-js';

import decisionViewBase from './components/DecisionViewBase';
import TextareaField from '../components/TextareaField';
import SearchableDropdown from '../components/SearchableDropdown';
import Alert from '../components/Alert';

import { highlightInvalidFormItems, requestSave } from './uiReducer/uiActions';
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
import Button from '../components/Button';

import type { Appeal, Task } from './types/models';
import type { UiStateMessage } from './types/state';

type AdminActionType = {|
  actionLabel: ?string,
  instructions: string,
  key: string
|};

type ComponentState = {|
  adminActions: Array<AdminActionType>
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
  highlightInvalidFormItems: typeof highlightInvalidFormItems,
  requestSave: typeof requestSave,
  onReceiveAmaTasks: typeof onReceiveAmaTasks,
  setAppealAttrs: typeof setAppealAttrs
|};

const adminActionTemplate = () => {
  return {
    actionLabel: null,
    instructions: '',
    key: _.uniqueId('action_')
  };
};

class AddColocatedTaskView extends React.PureComponent<Props, ComponentState> {
  constructor(props) {
    super(props);

    this.state = {
      adminActions: [adminActionTemplate()]
    };
  }

  removeAdminActionField = (index) => {
    const fields = [...this.state.adminActions];

    fields.splice(index, 1);
    this.setState({ adminActions: fields });
  }

  updateAdminActionField = (index, key, value) => {
    const fields = [...this.state.adminActions];

    fields[index][key] = value;
    this.setState({ adminActions: fields });
  }

  addAdminActionField = () => {
    this.props.highlightInvalidFormItems(false);
    this.setState({ adminActions: [...this.state.adminActions, adminActionTemplate()] });
  }

  validateForm = () => this.state.adminActions.every(
    (action) => Boolean(action.actionLabel) && Boolean(action.instructions)
  );

  buildPayload = () => {
    const { task, appeal } = this.props;

    return this.state.adminActions.map(
      (action) => {
        return {
          label: action.actionLabel,
          instructions: action.instructions,
          type: 'ColocatedTask',
          external_id: appeal.externalId,
          parent_id: appeal.isLegacyAppeal ? null : task.taskId
        };
      }
    );
  }

  goToNextStep = () => {
    const { task } = this.props;
    const payload = {
      data: {
        tasks: this.buildPayload()
      }
    };
    const msgTitle = COPY.ADD_COLOCATED_TASK_CONFIRMATION_TITLE;
    const msgSubject = pluralize(COPY.ADD_COLOCATED_TASK_CONFIRMATION_SUBJECT, this.state.adminActions.length);
    const msgActions = this.state.adminActions.map((action) => CO_LOCATED_ADMIN_ACTIONS[action.actionLabel]).join(', ');
    const msgDisplayCount = this.state.adminActions.length === 1 ? 'an' : this.state.adminActions.length;
    const successMsg = {
      title: sprintf(msgTitle, msgDisplayCount, msgSubject, msgActions),
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

  singleIssueTemplate = (action, total, index) => {
    const { highlightFormItems } = this.props;
    const { instructions, actionLabel, key } = action;

    return <React.Fragment key={key}>
      <div {...marginTop(4)}>
        <SearchableDropdown
          errorMessage={highlightFormItems && !actionLabel ? COPY.FORM_ERROR_FIELD_REQUIRED : null}
          name={COPY.ADD_COLOCATED_TASK_ACTION_TYPE_LABEL}
          placeholder="Select an action type"
          options={_.map(CO_LOCATED_ADMIN_ACTIONS, (label: string, value: string) => ({
            label,
            value
          }))}
          onChange={(option) => option && this.updateAdminActionField(index, 'actionLabel', option.value)}
          value={actionLabel} />
      </div>
      <div {...marginTop(4)}>
        <TextareaField
          errorMessage={highlightFormItems && !instructions ? COPY.FORM_ERROR_FIELD_REQUIRED : null}
          name={COPY.ADD_COLOCATED_TASK_INSTRUCTIONS_LABEL}
          onChange={(value) => this.updateAdminActionField(index, 'instructions', value)}
          value={instructions} />
      </div>
      {/* TODO: Put this text in COPY.json */}
      {total > 1 &&
        <React.Fragment>
          <Button
            willNeverBeLoading
            linkStyling
            styling={css({ paddingLeft: '0' })}
            name="Remove this action"
            onClick={() => this.removeAdminActionField(index)} />
          <br />
        </React.Fragment>
      }
      {index === total - 1 &&
        <Button
          dangerStyling
          willNeverBeLoading
          name="+ Add another action"
          onClick={() => this.addAdminActionField()} />
      }
    </React.Fragment>;
  };

  actionFormList = (actions) => {
    const total = actions.length;

    return (
      <React.Fragment>
        { actions.map((action, index) => this.singleIssueTemplate(action, total, index)) }
      </React.Fragment>
    );
  }

  render = () => {
    const { error } = this.props;
    const { adminActions } = this.state;

    return <React.Fragment>
      <h1 className="cf-push-left" {...css(fullWidth, marginBottom(1))}>
        {COPY.ADD_COLOCATED_TASK_SUBHEAD}
      </h1>
      <hr />
      {error && <Alert title={error.title} type="error">
        {error.detail}
      </Alert>}
      { this.actionFormList(adminActions) }
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
  highlightInvalidFormItems,
  requestSave,
  onReceiveAmaTasks,
  setAppealAttrs
}, dispatch);

const WrappedComponent = decisionViewBase(AddColocatedTaskView, {
  hideCancelButton: true,
  continueBtnText: 'Assign Action'
});

export default (connect(mapStateToProps, mapDispatchToProps)(WrappedComponent): React.ComponentType<Params>);
