import React from 'react';
import PropTypes from 'prop-types';
import ApiUtil from '../../../util/ApiUtil';
import { sprintf } from 'sprintf-js';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { updateLastAction } from '../correspondenceReducer/reviewPackageActions';
import TextareaField from '../../../components/TextareaField';
import RadioField from '../../../components/RadioField';
import COPY from '../../../../COPY';
import Modal from '../../../components/Modal';
import Button from '../../../components/Button';
import { Redirect } from 'react-router-dom';

class RemovePackageModal extends React.Component {

  constructor(props) {
    super(props);

    this.state = {
      reasonForRemove: null,
      disabledSaveButton: true,
      reasonReject: '',
      updateCancelSuccess: false
    };
  }

  handleSelect(reasonForRemove) {
    if (reasonForRemove === 'Approve request') {
      this.setState({ reasonForRemove,
        disabledSaveButton: false
      });
    } else {
      this.setState({ reasonForRemove,
        disabledSaveButton: true });
    }
  }

  reasonChange = (value) => {
    if (value.trim().length > 0) {
      this.setState({
        reasonReject: value,
        disabledSaveButton: false
      });
    } else {
      this.setState({
        reasonReject: '',
        disabledSaveButton: true
      });
    }
  }

  render() {
    const { onCancel } = this.props;
    const submit = () => {
      let selectedRequestChoice;

      if (this.state.reasonForRemove === 'Approve request') {
        selectedRequestChoice = 'approve';
      } else {
        selectedRequestChoice = 'reject';
      }

      try {
        const data = {
          action_type: 'remove',
          decision: selectedRequestChoice,
          decision_reason: this.state.reasonReject,
        };

        ApiUtil.patch(`/queue/correspondence/tasks/${this.props.blockingTaskId}/update`, { data }).
          then(() => {
            window.location.href = '/queue/correspondence/team';
          });

      } catch (error) {
        console.error(error);
      }
    };

    const removeReasonOptions = [
      { displayText: 'Approve request',
        value: 'Approve request' },
      { displayText: 'Reject request',
        value: 'Reject request' }
    ];

    if (this.state.updateCancelSuccess) {
      return <Redirect to="/queue/correspondence" />;
    }

    return (
      <Modal
        title= {sprintf(COPY.CORRESPONDENCE_HEADER_REMOVE_PACKAGE)}
        closeHandler={onCancel}
        confirmButton={<Button disabled={this.state.disabledSaveButton}
          onClick={submit}>Confirm</Button>}
        cancelButton={<Button linkStyling onClick={onCancel}>Cancel</Button>}
      >
        <p>
          <span className="modal-fwb">{sprintf(COPY.CORRESPONDENCE_TITLE_REMOVE_PACKAGE)}</span><br />
          {this.props.taskInstructions[0]}
        </p>

        <RadioField
          vertical
          label={sprintf(COPY.CORRRESPONDENCE_LABEL_OPTION_REMOVE_PACKAGE)}
          name="merge-package"
          value={this.state.reasonForRemove}
          options={removeReasonOptions}
          onChange={(val) => this.handleSelect(val)}
        />

        {this.state.reasonForRemove === 'Reject request' &&
              <TextareaField
                name={sprintf(COPY.CORRESPONDENCE_TITLE_REMOVE_PACKAGE_REASON_REJECT)}
                onChange={this.reasonChange}
                value={this.state.reasonReject}
              />
        }

      </Modal>
    );

  }
}

const mapStateToProps = (state) => {
  return { vetInfo: state.reviewPackage.lastAction,
    taskInstructions: state.reviewPackage.taskInstructions };
};

RemovePackageModal.propTypes = {
  blockingTaskId: PropTypes.number,
  modalState: PropTypes.bool,
  onCancel: PropTypes.func,
  setModalState: PropTypes.func,
  correspondence_id: PropTypes.number,
  vetInfo: PropTypes.object,
  taskInstructions: PropTypes.array,
  updateLastAction: PropTypes.func,
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  updateLastAction
}, dispatch);

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(RemovePackageModal);
