import * as React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { withRouter } from 'react-router-dom';
import { sprintf } from 'sprintf-js';
import { requestPatch } from '../uiReducer/uiActions';
import { taskById } from '../selectors';
import { marginTop } from '../constants';
import { taskActionData } from '../utils';
import QueueFlowModal from '../components/QueueFlowModal';
import TextareaField from "app/components/TextareaField";
import SearchableDropdown from "app/components/SearchableDropdown";
import Alert from "app/components/Alert";
import COPY from '../../../COPY';

class CorrespondenceChangeTaskTypeModal extends React.PureComponent {

  constructor(props) {
    super(props);

    this.state = {
      typeOption: null,
      instructions: '',
    };
  }

  validateForm = () => Boolean(this.state.typeOption) && Boolean(this.state.instructions);

  buildPayload = () => {
    const { typeOption, instructions } = this.state;

    return {
      data: {
        task: {
          type: typeOption.value,
          instructions: instructions.value
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

    return this.props.requestPatch(`/queue/correspondence/tasks/${task.taskId}/change_task_type`, payload, successMsg).
      then((response) => {
        console.log(response);
      }).
      catch(() => {
        // handle the error from the frontend
      });
  }

  actionForm = () => {
    const { instructions, typeOption } = this.state;

    return <React.Fragment>
      <div>
        <div {...marginTop(4)}>
          <SearchableDropdown
            name={COPY.CHANGE_TASK_TYPE_ACTION_LABEL}
            placeholder="Select an action type..."
            options={taskActionData(this.props).options}
            onChange={(option) => option && this.setState({ typeOption: option })}
            value={typeOption && typeOption.value} />
        </div>
        <div {...marginTop(4)}>
          <TextareaField
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
      pathAfterSubmit={`/queue/correspondence/${this.props.correspondence_uuid}`}
      submitButtonClassNames={['usa-button']}
      submitDisabled={!this.validateForm()}
    >
      {error && <Alert title={error.title} type="error">
        {error.detail}
      </Alert>}
      { this.actionForm() }
    </QueueFlowModal>;
  }
}

CorrespondenceChangeTaskTypeModal.propTypes = {
  correspondence_uuid: PropTypes.string,
  error: PropTypes.shape({
    title: PropTypes.string,
    detail: PropTypes.string
  }),
  requestPatch: PropTypes.func,
  task: PropTypes.shape({
    taskId: PropTypes.string,
    label: PropTypes.string
  })
};

const mapStateToProps = (state, ownProps) => ({
  error: state.ui.messages.error,
  task: taskById(state, { taskId: ownProps.task_id })
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  requestPatch
}, dispatch);

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(CorrespondenceChangeTaskTypeModal));
