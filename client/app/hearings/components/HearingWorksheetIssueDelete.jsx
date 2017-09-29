import React, { PureComponent } from 'react';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { toggleIssueDeleteModal } from '../actions/Issue';
import Modal from '../../components/Modal';
import { TrashCan } from '../../components/RenderFunctions';

class HearingWorksheetIssueDelete extends PureComponent {

  handleModalOpen = () => {
    this.props.toggleIssueDeleteModal(true);
  };

  handleModalClose = () => {
    this.props.toggleIssueDeleteModal(false);
  };

  render() {
    return <div className="cf-issue-delete"
                        onClick={this.handleModalOpen}
                        alt="Remove Issue Confirmation">
                        <TrashCan />
                </div>;
    { issueDeleteModal && <Modal
          buttons = {[
            { classNames: ['usa-button', 'usa-button-outline'],
              name: 'Close',
              onClick: this.handleModalClose
            },
            { classNames: ['usa-button', 'usa-button-primary'],
              name: 'Yes',
              onClick: this.handleModalClose
            }
          ]}
          closeHandler={this.handleModalClose}
          noDivider={true}
          title = "Remove Issue Row">
          <p>Are you sure you want to remove this issue from Appeal Stream 1 on the worksheet? </p>
          <p>This issue will be removed from the worksheet, but will remain in VACOLS.</p>
        </Modal>;
    }
  }

  }

const mapStateToProps = (state) => ({
  issueDeleteModal: state.issueDeleteModal
});

HearingWorksheetIssueFields.propTypes = {
  issue: PropTypes.object.isRequired,
  appeal: PropTypes.object.isRequired,
  issueDeleteModal: PropTypes.bool.isRequired
};

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(HearingWorksheetIssueFields);

