import * as React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { withRouter } from 'react-router-dom';
import { sprintf } from 'sprintf-js';

import TextareaField from '../components/TextareaField';
import SearchableDropdown from '../components/SearchableDropdown';
import Alert from '../components/Alert';

import { highlightInvalidFormItems, requestPatch } from './uiReducer/uiActions';
import { setAppealAttrs, onReceiveAmaTasks } from './QueueActions';

import {
  appealWithDetailSelector,
  taskById
} from './selectors';
import { marginTop } from './constants';
import COPY from '../../COPY.json';

import { taskActionData } from './utils';
import QueueFlowModal from './components/QueueFlowModal';

class ChangeTaskTypeModal extends React.PureComponent {

  constructor(props) {
    super(props);

    this.state = {
      typeOption: null,
      instructions: ''
    };
  }

  validateForm = () => Boolean(this.state.typeOption) && Boolean(this.state.instructions);

  buildPayload = () => {
    const { typeOption, instructions } = this.state;

    return {
      data: {
        task: {
          type: typeOption.value,
          instructions
        }
      }
    };
  }

  submit = () => {
    const { task } = this.props;
    const { typeOption } = this.state;

    const payload = this.buildPayload();

    const successMsg = {
      title: sprintf(COPY.CHANGE_TASK_TYPE_CONFIRMATION_TITLE, task.label, typeOption.label),
      detail: COPY.CHANGE_TASK_TYPE_CONFIRMATION_DETAIL
    };

    return this.props.requestPatch(`/tasks/${task.taskId}/change_type`, payload, successMsg).
      then((response) => {
        this.props.onReceiveAmaTasks({ amaTasks: response.body.tasks.data });
      }).
      catch(() => {
        // handle the error from the frontend
      });
  }

  actionForm = () => {
    const { highlightFormItems } = this.props;
    const { instructions, typeOption } = this.state;

    return <React.Fragment>
      <div>
        <div {...marginTop(4)}>
          <SearchableDropdown
            errorMessage={highlightFormItems && !typeOption ? COPY.FORM_ERROR_FIELD_REQUIRED : null}
            name={COPY.CHANGE_TASK_TYPE_ACTION_LABEL}
            placeholder="Select an action type"
            options={taskActionData(this.props).options}
            onChange={(option) => option && this.setState({ typeOption: option })}
            value={typeOption && typeOption.value} />
        </div>
        <div {...marginTop(4)}>
          <TextareaField
            errorMessage={highlightFormItems && !instructions ? COPY.FORM_ERROR_FIELD_REQUIRED : null}
            name={COPY.CHANGE_TASK_TYPE_INSTRUCTIONS_LABEL}
            onChange={(value) => this.setState({ instructions: value })}
            value={instructions} />
        </div>
      </div>
    </React.Fragment>;
  };

  render = () => {
    const { error } = this.props;

    return <QueueFlowModal
      validateForm={this.validateForm}
      submit={this.submit}
      title={COPY.CHANGE_TASK_TYPE_SUBHEAD}
      button={COPY.CHANGE_TASK_TYPE_SUBHEAD}
      pathAfterSubmit={`/queue/appeals/${this.props.appealId}`}
    >
      {error && <Alert title={error.title} type="error">
        {error.detail}
      </Alert>}
      { this.actionForm() }
    </QueueFlowModal>;
  }
}

ChangeTaskTypeModal.propTypes = {
  appealId: PropTypes.string,
  error: PropTypes.shape({
    title: PropTypes.string,
    detail: PropTypes.string
  }),
  highlightFormItems: PropTypes.bool,
  highlightInvalidFormItems: PropTypes.func,
  onReceiveAmaTasks: PropTypes.func,
  requestPatch: PropTypes.func,
  setAppealAttrs: PropTypes.func,
  task: PropTypes.shape({
    taskId: PropTypes.string,
    label: PropTypes.string
  })
};

const mapStateToProps = (state, ownProps) => ({
  highlightFormItems: state.ui.highlightFormItems,
  error: state.ui.messages.error,
  appeal: appealWithDetailSelector(state, ownProps),
  task: taskById(state, { taskId: ownProps.taskId })
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  highlightInvalidFormItems,
  requestPatch,
  onReceiveAmaTasks,
  setAppealAttrs
}, dispatch);

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(ChangeTaskTypeModal));
