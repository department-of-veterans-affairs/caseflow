import * as React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { withRouter } from 'react-router-dom';
import { isArray, find } from 'lodash';
import moment from 'moment';

import COPY from '../../COPY';
import { DISPOSITION_OPTIONS } from '../hearings/constants';
import DISPOSITION_TYPES from '../../constants/HEARING_DISPOSITION_TYPES';
import TASK_STATUSES from '../../constants/TASK_STATUSES';

import { taskById, appealWithDetailSelector } from './selectors';

import { onReceiveAmaTasks } from './QueueActions';

import SearchableDropdown from '../components/SearchableDropdown';
import TextareaField from '../components/TextareaField';
import QueueFlowModal from './components/QueueFlowModal';

import { requestPatch } from './uiReducer/uiActions';
import { dispositionLabel } from '../hearings/utils';

class ChangeHearingDispositionModal extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      error: null,
      selectedValue: null,
      instructions: ''
    };
  }

  submit = () => {
    const { task } = this.props;

    const disposition = {
      disposition: this.state.selectedValue
    };
    let afterDispositionUpdate = {};

    if (this.state.selectedValue === DISPOSITION_TYPES.postponed ||
      this.state.selectedValue === DISPOSITION_TYPES.scheduled_in_error) {
      afterDispositionUpdate = {
        after_disposition_update: {
          action: 'schedule_later'
        }
      };
    }

    const values = {
      ...disposition,
      ...afterDispositionUpdate
    };

    const payload = {
      data: {
        task: {
          status: TASK_STATUSES.cancelled,
          instructions: this.state.instructions,
          business_payloads: {
            values
          }
        }
      }
    };

    const successMsg = {
      title: `Successfully changed hearing disposition to ${dispositionLabel(this.state.selectedValue)}`
    };

    return this.props.
      requestPatch(`/tasks/${task.taskId}`, payload, successMsg).
      then((resp) => {
        this.props.onReceiveAmaTasks(resp.body.tasks.data);
      }).
      catch((err) => {
        // Process the error from the response
        const message = err?.message ? JSON.parse(err?.message) : {};
        const error = isArray(message.errors) ? message.errors[0] : err;

        // Set the state with the error to show the message
        this.setState({
          error
        });

        // Throw the error to prevent the Modal from closing
        throw error;
      });
  };

  validateForm = () => {
    return this.state.selectedValue !== null && this.state.instructions !== '';
  };

  render = () => {
    const { appeal, highlightFormItems, task } = this.props;

    const hearing = find(appeal.hearings, { externalId: task.externalHearingId });
    const currentDisposition = dispositionLabel(hearing?.disposition);

    return (
      <QueueFlowModal
        title="Change hearing disposition"
        pathAfterSubmit="/queue"
        submit={this.submit}
        validateForm={this.validateForm}
      >
        <p>
          Changing the hearing disposition for this case will close all the open tasks and will remove the case from the
          current workflow.
        </p>

        <p>
          <strong>Hearing Date:</strong> {moment(hearing?.date).format('MM/DD/YYYY')}
        </p>
        <p>
          <strong>Current Disposition:</strong> {currentDisposition}
        </p>

        <SearchableDropdown
          name="New Disposition"
          errorMessage={highlightFormItems && !this.state.selectedValue ? 'Choose one' : null}
          placeholder="Select"
          value={this.state.selectedValue}
          onChange={(option) => this.setState({ selectedValue: option ? option.value : null })}
          options={DISPOSITION_OPTIONS}
        />
        <br />
        <TextareaField
          name="Notes"
          errorMessage={highlightFormItems && !this.state.instructions ? COPY.FORM_ERROR_FIELD_REQUIRED : null}
          id="taskInstructions"
          onChange={(value) => this.setState({ instructions: value })}
          value={this.state.instructions}
        />
      </QueueFlowModal>
    );
  };
}

ChangeHearingDispositionModal.propTypes = {
  appeal: PropTypes.object,
  highlightFormItems: PropTypes.bool,
  onReceiveAmaTasks: PropTypes.func,
  requestPatch: PropTypes.func,
  task: PropTypes.shape({
    taskId: PropTypes.string,
    externalHearingId: PropTypes.string
  })
};

const mapStateToProps = (state, ownProps) => {
  const { highlightFormItems } = state.ui;

  return {
    highlightFormItems,
    task: taskById(state, { taskId: ownProps.taskId }),
    appeal: appealWithDetailSelector(state, ownProps)
  };
};

const mapDispatchToProps = (dispatch) =>
  bindActionCreators(
    {
      requestPatch,
      onReceiveAmaTasks
    },
    dispatch
  );

export default withRouter(
  connect(
    mapStateToProps,
    mapDispatchToProps
  )(ChangeHearingDispositionModal)
);
