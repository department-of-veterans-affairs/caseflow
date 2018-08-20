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
import { deleteAppeal } from './QueueActions';

import {
  fullWidth,
  marginBottom,
  marginTop
} from './constants';
import COPY from '../../COPY.json';
import CO_LOCATED_ADMIN_ACTIONS from '../../constants/CO_LOCATED_ADMIN_ACTIONS.json';

import type { Appeal } from './types/models';
import type { UiStateMessage } from './types/state';

type ComponentState = {|
  action: ?string,
  instructions: string
|};

type Params = {|
  appealId: string
|};

type Props = Params & {|
  // store
  highlightFormItems: boolean,
  error: ?UiStateMessage,
  appeal: Appeal,
  // dispatch
  requestSave: typeof requestSave,
  deleteAppeal: typeof deleteAppeal
|};

class AddColocatedTaskView extends React.PureComponent<Props, ComponentState> {
  constructor(props) {
    super(props);

    this.state = {
      action: null,
      instructions: ''
    };
  }

  validateForm = () => Object.values(this.state).every(Boolean);

  goToNextStep = () => {
    const payload = {
      data: {
        tasks: [{
          ...this.state,
          type: 'ColocatedTask',
          external_id: this.props.appeal.externalId
        }]
      }
    };
    const successMsg = {
      title: sprintf(COPY.ADD_COLOCATED_TASK_CONFIRMATION_TITLE, CO_LOCATED_ADMIN_ACTIONS[this.state.action]),
      detail: COPY.ADD_COLOCATED_TASK_CONFIRMATION_DETAIL
    };

    this.props.requestSave('/tasks', payload, successMsg).
      then(() => this.props.deleteAppeal(this.props.appealId));
  }

  render = () => {
    const { highlightFormItems, error } = this.props;
    const { action, instructions } = this.state;

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
          errorMessage={highlightFormItems && !action ? COPY.FORM_ERROR_FIELD_REQUIRED : null}
          name={COPY.ADD_COLOCATED_TASK_ACTION_TYPE_LABEL}
          placeholder="Select an action type"
          options={_.map(CO_LOCATED_ADMIN_ACTIONS, (label: string, value: string) => ({
            label,
            value
          }))}
          onChange={({ value }) => this.setState({ action: value })}
          value={this.state.action} />
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
  appeal: state.queue.appealDetails[ownProps.appealId]
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  requestSave,
  deleteAppeal
}, dispatch);

const WrappedComponent = decisionViewBase(AddColocatedTaskView, {
  hideCancelButton: true,
  continueBtnText: 'Assign Action'
});

export default (connect(mapStateToProps, mapDispatchToProps)(WrappedComponent): React.ComponentType<Params>);
