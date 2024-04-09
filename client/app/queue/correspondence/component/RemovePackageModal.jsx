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

  removePackage = async () => {
    try {
      ApiUtil.post(`/queue/correspondence/${this.props.correspondence_id}/remove_package`).
        then(() => {
          this.setState({
            updateCancelSuccess: true
          });
          this.props.updateLastAction('DeleteReviewPackage');
        });

    } catch (error) {
      console.error(error);
    }
  }

  completePackage = async () => {
    try {
      const data = {
        correspondence_id: this.props.correspondence_id,
        instructions: []
      };

      data.instructions.push(this.state.reasonReject);

      ApiUtil.post(`/queue/correspondence/${this.props.correspondence_id}/completed_package`, { data }).
        then(() => {
          this.setState({
            updateCancelSuccess: true
          });
          this.props.updateLastAction('InProgressReviewPackage');
        });

    } catch (error) {
      console.error(error);
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
      const newUrl = new URL(window.location.href);
      const searchParams = new URLSearchParams(newUrl.search);
      const taskId = this.props.reviewDetails.taskId;
      const veteranName = this.props.reviewDetails.veteranName;

      // Encode and set the query parameters
      searchParams.set('taskId', encodeURIComponent(taskId));
      searchParams.set('veteranName', encodeURIComponent(veteranName));
      searchParams.set('userAction', encodeURIComponent(selectedRequestChoice));
      searchParams.set('decisionReason', encodeURIComponent(this.state.reasonReject));
      searchParams.set('operation', encodeURIComponent('remove'));
      searchParams.set('tab', encodeURIComponent('correspondence_unassigned'));
      searchParams.set('page', encodeURIComponent('1'));

      // Construct the new URL with encoded query parameters
      newUrl.search = searchParams.toString();
      newUrl.pathname = '/queue/correspondence/team';
      window.location.href = newUrl.href;
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
          <span style= {{ fontWeight: 'bold' }}>{sprintf(COPY.CORRESPONDENCE_TITLE_REMOVE_PACKAGE)}</span><br />
          {this.props.reasonRemovePackage[0]}
        </p>

        <RadioField
          vertical
          label= {sprintf(COPY.CORRRESPONDENCE_LABEL_OPTION_REMOVE_PACKAGE)}
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
    reasonRemovePackage: state.reviewPackage.reasonForRemovePackage };
};

RemovePackageModal.propTypes = {
  reviewDetails: PropTypes.object,
  modalState: PropTypes.bool,
  onCancel: PropTypes.func,
  setModalState: PropTypes.func,
  correspondence_id: PropTypes.number,
  vetInfo: PropTypes.object,
  reasonRemovePackage: PropTypes.object,
  updateLastAction: PropTypes.func,
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  updateLastAction
}, dispatch);

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(RemovePackageModal);
