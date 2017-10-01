import React, { PureComponent } from 'react';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { toggleIssueDeleteModal, onDeleteIssue } from '../actions/Issue';
import Modal from '../../components/Modal';
import { TrashCan } from '../../components/RenderFunctions';


class HearingWorksheetIssueDelete extends PureComponent {

  handleModalOpen = (issueKey, appealKey) => () => {
    this.props.toggleIssueDeleteModal(issueKey, appealKey, true);
  };

  handleModalClose = (issueKey, appealKey) => () => {
    this.props.toggleIssueDeleteModal(issueKey, appealKey, false);
  };

  onDeleteIssue = (appealKey, issueKey) => () => {
    this.props.onDeleteIssue(issueKey, appealKey);
  };

  render() {
    let {
      appealKey,
      issueKey
    } = this.props;

    const issue = this.props.worksheet.streams[appealKey].worksheet_issues[issueKey];

    return <div>
      <div
        className="cf-issue-delete"
        onClick={this.handleModalOpen(issueKey, appealKey)}
        alt="Remove Issue Confirmation">
        <TrashCan />
      </div>
      { issue.isShowingModal && <Modal
          buttons = {[
            { classNames: ['usa-button', 'usa-button-outline'],
              name: 'Close',
              onClick: this.handleModalClose(issueKey, appealKey)
            },
            { classNames: ['usa-button', 'usa-button-primary'],
              name: 'Yes',
              onClick: this.onDeleteIssue(appealKey, issueKey)
            }]}
          closeHandler={this.handleModalClose(issueKey, appealKey)}
          noDivider={true}
          title = "Remove Issue Row">
          <p>Are you sure you want to remove this issue from Appeal Stream 1 on the worksheet? </p>
          <p>This issue will be removed from the worksheet, but will remain in VACOLS.</p>
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

