import React, { PureComponent } from 'react';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { toggleIssueDeleteModal, onDeleteIssue } from '../../actions/hearingWorksheetActions';
import Modal from '../../../components/Modal';
import { trashCan } from '../../../components/RenderFunctions';

class HearingWorksheetIssueDelete extends PureComponent {
  handleModalOpen = (issueId) => () => {
    this.props.toggleIssueDeleteModal(issueId, true);
  };

  handleModalClose = (issueId) => () => {
    this.props.toggleIssueDeleteModal(issueId, false);
  };

  onDeleteIssue = (issueId) => () => {
    this.props.onDeleteIssue(issueId);
    this.props.toggleIssueDeleteModal(issueId, false);
  };

  render() {
    let { issue, appealKey } = this.props;

    return (
      <div>
        <button
          id={`cf-issue-delete-${issue.appeal_id}${issue.id}`}
          className="cf-issue-delete"
          onClick={this.handleModalOpen(issue.id)}
          alt="Remove Issue Confirmation"
          name="Delete Issue"
          aria-label="Delete Issue"
          type="button"
        >
          {trashCan()}
        </button>
        <Modal
          show={issue.isShowingModal}
          buttons={[
            { classNames: ['cf-modal-link', 'cf-btn-link'], name: 'Cancel', onClick: this.handleModalClose(issue.id) },
            {
              classNames: ['usa-button', 'usa-button-secondary'],
              name: 'Confirm delete',
              onClick: this.onDeleteIssue(issue.id)
            }
          ]}
          closeHandler={this.handleModalClose(issue.id)}
          title="Delete Issue Row"
        >
          <p>Are you sure you want to remove this issue from Appeal Stream {appealKey + 1} on the worksheet? </p>
          {issue.from_vacols && <p>This issue will be removed from the worksheet, but will remain in VACOLS.</p>}
        </Modal>
      </div>
    );
  }
}

const mapStateToProps = (state) => ({
  worksheet: state.hearingWorksheet
});

const mapDispatchToProps = (dispatch) =>
  bindActionCreators(
    {
      toggleIssueDeleteModal,
      onDeleteIssue
    },
    dispatch
  );

HearingWorksheetIssueDelete.propTypes = {
  issue: PropTypes.object.isRequired,
  appeal: PropTypes.object.isRequired
};

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(HearingWorksheetIssueDelete);
