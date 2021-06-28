import _ from 'lodash';
import * as React from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { withRouter } from 'react-router-dom';
import { css } from 'glamor';

import COPY from '../../../COPY';
import QueueFlowModal from './QueueFlowModal';
import RegionalOfficeDropdown from '../../components/DataDropdowns/RegionalOffice';
import TextareaField from '../../components/TextareaField';
import { taskById } from '../selectors';
import { taskActionData } from '../utils';
import { highlightInvalidFormItems, requestPatch } from '../uiReducer/uiActions';

class UpdateTaskStatusAssignRegionalOfficeModal extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      regionalOffice: null,
      notes: ''
    };
  }

  onRegionalOfficeSelected = (value) => {
    this.setState({ regionalOffice: value });
    this.props.highlightInvalidFormItems(false);
  }

  validateRegionalOfficePopulated = () => !_.isNull(this.state.regionalOffice);

  onNotesChanged = (notes) => this.setState({ notes });

  onSubmit = () => {
    const { updateStatusTo, task, actionConfiguration } = this.props;
    const { regionalOffice, notes } = this.state;
    const payload = {
      data: {
        task: {
          status: updateStatusTo,
          instructions: notes,
          business_payloads: {
            values: {
              regional_office_value: regionalOffice.key
            }
          }
        }
      }
    };
    const successMessage = {
      title: actionConfiguration.message_title || 'Success',
      detail: actionConfiguration.message_detail || ''
    };

    return this.props.requestPatch(`/tasks/${task.taskId}`, payload, successMessage);
  };

  render = () => {
    const { actionConfiguration, appealId, hasError } = this.props;

    return (
      <QueueFlowModal
        title={actionConfiguration.modal_title || ''}
        button={COPY.MODAL_CONFIRM_BUTTON}
        submit={this.onSubmit}
        validateForm={this.validateRegionalOfficePopulated}
        pathAfterSubmit={`/queue/appeals/${appealId}`}
      >
        {actionConfiguration.modal_body && <p>{actionConfiguration.modal_body}</p>}
        <RegionalOfficeDropdown
          errorMessage={hasError ? COPY.REGIONAL_OFFICE_REQUIRED_MESSAGE : null}
          excludeVirtualHearingsOption
          value={this.state.regionalOffice}
          onChange={this.onRegionalOfficeSelected}
        />
        <TextareaField
          label="Notes"
          name="notes"
          strongLabel
          textAreaStyling={css({ height: '100px' })}
          onChange={this.onNotesChanged}
        />
      </QueueFlowModal>
    );
  }
}

const mapStateToProps = (state, ownProps) => {
  const task = taskById(state, { taskId: ownProps.taskId });

  return {
    task,
    actionConfiguration: taskActionData({ task,
      ...ownProps }),
    appealId: ownProps.appealId,
    hasError: state.ui.highlightFormItems
  };
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  highlightInvalidFormItems,
  requestPatch
}, dispatch);

UpdateTaskStatusAssignRegionalOfficeModal.propTypes = {
  actionConfiguration: PropTypes.object.isRequired,
  appealId: PropTypes.string.isRequired,
  hasError: PropTypes.bool.isRequired,
  highlightInvalidFormItems: PropTypes.func,
  requestPatch: PropTypes.func,
  task: PropTypes.object.isRequired,
  updateStatusTo: PropTypes.string.isRequired,
};

export default (withRouter(
  connect(mapStateToProps, mapDispatchToProps)(
    UpdateTaskStatusAssignRegionalOfficeModal
  )
));
