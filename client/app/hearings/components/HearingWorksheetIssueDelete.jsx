import React, { PureComponent } from 'react';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { toggleIssueDeleteModal, onDeleteIssue } from '../actions/Issue';
import Modal from '../../components/Modal';
import { TrashCan } from '../../components/RenderFunctions';


class HearingWorksheetIssueDelete extends PureComponent {

  handleModalOpen = (appealKey, issueKey) => () => {
    this.props.toggleIssueDeleteModal(appealKey, issueKey, true);
  };

  handleModalClose = (appealKey, issueKey) => () => {
    this.props.toggleIssueDeleteModal(appealKey, issueKey, false);
  };

  onDeleteIssue = (appealKey, issueKey) => () => {
    this.props.onDeleteIssue(appealKey, issueKey);
    this.props.toggleIssueDeleteModal(appealKey, issueKey, false);
  };

  render() {
    let {
      appealKey,
      issueKey
    } = this.props;

    const issue = this.props.worksheet.appeals_ready_for_hearing[appealKey].worksheet_issues[issueKey];

    return <div>
      <div
        id={`cf-issue-delete-${appealKey}${issueKey}`}
        className="cf-issue-delete"
        onClick={this.handleModalOpen(appealKey, issueKey)}
        alt="Remove Issue Confirmation">
        <TrashCan />
      </div>
      { issue.isShowingModal && <Modal
          buttons = {[
            { classNames: ['cf-modal-link', 'cf-btn-link'],
              name: 'Cancel',
              onClick: this.handleModalClose(appealKey, issueKey)
            },
            { classNames: ['usa-button', 'usa-button-secondary'],
              name: 'Confirm delete',
              onClick: this.onDeleteIssue(appealKey, issueKey)
            }]}
          closeHandler={this.handleModalClose(appealKey, issueKey)}
          title = "Delete Issue Row">
          <p>Are you sure you want to remove this issue from Appeal Stream {appealKey + 1} on the worksheet? </p>
          { issue.from_vacols && <p>This issue will be removed from the worksheet, but will remain in VACOLS.</p> }
        </Modal>
      }
    </div>;
  }
}

const mapStateToProps = (state) => ({
  worksheet: state.worksheet
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  toggleIssueDeleteModal,
  onDeleteIssue
}, dispatch);

HearingWorksheetIssueDelete.propTypes = {
  issue: PropTypes.object.isRequired,
  appeal: PropTypes.object.isRequired
};

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(HearingWorksheetIssueDelete);

