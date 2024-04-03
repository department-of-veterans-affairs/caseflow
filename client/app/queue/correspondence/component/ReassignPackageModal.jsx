import React from 'react';
import PropTypes from 'prop-types';
import ApiUtil from '../../../util/ApiUtil';
import { sprintf } from 'sprintf-js';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { updateLastReassignAction } from '../correspondenceReducer/reviewPackageActions';
import TextareaField from '../../../components/TextareaField';
import ReactSelectDropdown from '../../../components/ReactSelectDropdown';
import COPY from '../../../../COPY';
import Modal from '../../../components/Modal';
import Button from '../../../components/Button';
import { Redirect } from 'react-router-dom';
import RadioFieldWithChildren from '../../../components/RadioFieldWithChildren';

class ReassignPackageModal extends React.Component {

  constructor(props) {
    super(props);

    this.state = {
      reasonForRemove: null,
      disabledSaveButton: true,
      reasonReject: '',
      updateCancelSuccess: false,
      selectedMailTeamUser: '',
      selectedRequestChoice: '',
      decisionReason: '',
      vetName: ''
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
    const submit = (operation) => {
      let newUrl = new URL(window.location.href);
      const modifyURL = newUrl.href
      const searchString = '/queue/correspondence'
      const index = modifyURL.indexOf(searchString);
      const updatedUrl = `${modifyURL.substring(0, index + searchString.length)}/team`;

      newUrl = new URL(updatedUrl);
      console.log(updatedUrl);
      const searchParams = new URLSearchParams(newUrl.search);

      // Encode and set the query parameters
      searchParams.set('user', encodeURIComponent(this.state.selectedMailTeamUser));
      searchParams.set('taskId', encodeURIComponent(this.props.veteranInformation.correspondence_tasks[2].id));
      searchParams.set('userAction', encodeURIComponent(this.state.selectedRequestChoice));
      searchParams.set('decisionReason', encodeURIComponent(this.state.decisionReason));
      searchParams.set('operation', encodeURIComponent(operation));

      // Construct the new URL with encoded query parameters
      newUrl.search = searchParams.toString();
      window.location.href = newUrl.href;
    };


    const confirmButtonDisabled = () => {
      const selectedRequestChoice = this.state.selectedRequestChoice;
      const selectedMailTeamUser = this.state.selectedMailTeamUser;
      const reassignModalVisible = this.props.modalState;
      const decisionReason = this.state.decisionReason;

      if (selectedRequestChoice === 'approve' && selectedMailTeamUser === '' && reassignModalVisible) {
        return true;
      }

      if (selectedRequestChoice === 'reject' && decisionReason === '') {
        return true;
      }

      if (selectedRequestChoice === '') {
        return true;
      }

      return false;
    };

    const buildMailUserData = (data) => {

      if (typeof data === 'undefined') {
        return [];
      }

      return data.map((user) => {
        return {
          value: user,
          label: user
        };
      });
    };

    const handleSetSelectedMailTeamUser = (selectedUser) => {
      this.setState({ selectedMailTeamUser: selectedUser });
    };

    const handleDecisionReason = (decisionText) => {
      this.setState({ decisionReason: decisionText });
    };

    const resetState = () => {
      this.setState({ selectedMailTeamUser: '' });
      this.setState({ selectedRequestChoice: '' });
      this.setState({ decisionReason: '' });
    };

    const handleSelectedRequestChoice = (selectedRequest) => {
      resetState();
      this.setState({ selectedRequestChoice: selectedRequest });
    };

    const approveElement = (<div style={{ width: '28vw' }}>
      <ReactSelectDropdown
        className="cf-margin-left-2rem img"
        label="Assign to person"
        onChangeMethod={(val) => handleSetSelectedMailTeamUser(val.value)}
        options={buildMailUserData(this.props.mailTeamUsers)}
      />
    </div>);

    const textAreaElement = (
      <div style={{ width: '280%' }}>
        <TextareaField label="Provide a reason for rejection"
          onChange={handleDecisionReason}
          value={this.state.decisionReason} />
      </div>);

    const reassignReasonOptions = [
      {
        displayText: 'Approve request',
        value: 'approve',
        element: approveElement,
        displayElement: this.state.selectedRequestChoice === 'approve'
      },
      {
        displayText: 'Reject request',
        value: 'reject',
        element: textAreaElement,
        displayElement: this.state.selectedRequestChoice === 'reject'
      }
    ];

    if (this.state.updateCancelSuccess) {
      return <Redirect to="/queue/correspondence" />;
    }

    return (
      <Modal
        title= {sprintf(COPY.CORRESPONDENCE_HEADER_REMOVE_PACKAGE)}
        closeHandler={onCancel}
        confirmButton={<Button disabled={(confirmButtonDisabled())}
          onClick={() => (submit('reassign'))}>Confirm</Button>}
        cancelButton={<Button linkStyling onClick={onCancel}>Cancel</Button>}
      >
        <p>
          <span style= {{ fontWeight: 'bold' }}>{sprintf(COPY.CORRESPONDENCE_TITLE_REASSIGN_PACKAGE)}</span><br />
          {this.props.reasonRemovePackage[0]}
        </p>

        <RadioFieldWithChildren
          vertical
          label= {sprintf(COPY.CORRRESPONDENCE_LABEL_OPTION_REASSIGN_PACKAGE)}
          name="merge-package"
          value={this.state.selectedRequestChoice}
          options={reassignReasonOptions}
          onChange={(val) => handleSelectedRequestChoice(val)}
        />

      </Modal>
    );

  }
}

const mapStateToProps = (state) => {
  return { vetInfo: state.reviewPackage.lastAction,
    reasonRemovePackage: state.reviewPackage.reasonForRemovePackage,
    reassignModalVisible: state.intakeCorrespondence.showReassignPackageModal,
    currentAction: state.reviewPackage.lastAction,
    veteranInformation: state.reviewPackage.veteranInformation,
    currentSelectedVeteran: state.intakeCorrespondence.selectedVeteranDetails
  };
};

ReassignPackageModal.propTypes = {
  modalState: PropTypes.bool,
  onCancel: PropTypes.func,
  setModalState: PropTypes.func,
  correspondence_id: PropTypes.number,
  vetInfo: PropTypes.object,
  reasonRemovePackage: PropTypes.object,
  updateLastAction: PropTypes.func,
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  updateLastReassignAction
}, dispatch);

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(ReassignPackageModal);
