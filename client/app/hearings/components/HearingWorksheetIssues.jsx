import React, { PureComponent } from 'react';
import Table from '../../components/Table';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import HearingWorksheetIssueFields from './HearingWorksheetIssueFields';
import HearingWorksheetPreImpressions from './HearingWorksheetPreImpressions';
import Modal from '../../components/Modal';
import { toggleIssueDeleteModal } from '../actions/Issue';

import { TrashCan } from '../../components/RenderFunctions';

class HearingWorksheetIssues extends PureComponent {

  handleModalOpen = () => {
    this.props.toggleIssueDeleteModal(true);
  };

  handleModalClose = () => {
    this.props.toggleIssueDeleteModal(false);
  };

  getKeyForRow = (index) => index;

  render() {
    let {
      worksheetStreamsIssues,
      worksheetStreamsAppeal,
      appealKey,
     issueDeleteModal
    } = this.props;


    const columns = [
      {
        header: '',
        valueName: 'counter'
      },
      {
        header: 'Program',
        align: 'left',
        valueName: 'program'
      },
      {
        header: 'Issue',
        align: 'left',
        valueName: 'issue'
      },
      {
        header: 'Levels 1-3',
        align: 'left',
        valueName: 'levels'
      },
      {
        header: 'Description',
        align: 'left',
        valueName: 'description'
      },
      {
        header: 'Preliminary Impressions',
        align: 'left',
        valueName: 'actions'
      },
      {
        header: '',
        align: 'left',
        valueName: 'deleteIssue'
      }
    ];

    // Maps over all issues inside stream
    const rowObjects = Object.keys(worksheetStreamsIssues).map((issue, key) => {

      let issueRow = worksheetStreamsIssues[issue];

      return {
        counter: <b>{key + 1}.</b>,
        program: <HearingWorksheetIssueFields
            appeal={worksheetStreamsAppeal}
            issue={issueRow}
            field="program"
            appealKey={appealKey}
            issueKey={key}
        />,
        issue: <HearingWorksheetIssueFields
            appeal={worksheetStreamsAppeal}
            issue={issueRow}
            field="name"
            appealKey={appealKey}
            issueKey={key}
        />,
        levels: <HearingWorksheetIssueFields
            appeal={worksheetStreamsAppeal}
            issue={issueRow}
            field="levels"
            appealKey={appealKey}
            issueKey={key}
        />,
        description: <HearingWorksheetIssueFields
            appeal={worksheetStreamsAppeal}
            issue={issueRow}
            field="description"
            appealKey={appealKey}
            issueKey={key}
        />,
        actions: <HearingWorksheetPreImpressions
                    appeal={worksheetStreamsAppeal}
                    issue={issueRow}
                    appealKey={appealKey}
                    issueKey={key}
        />,
        deleteIssue: <div className="cf-issue-delete"
                        onClick={this.handleModalOpen}
                        alt="Remove Issue Confirmation">
                        <TrashCan />
                    </div>
      };
    });

    return <div>
          <Table
              className="cf-hearings-worksheet-issues"
              columns={columns}
              rowObjects={rowObjects}
              summary={'Worksheet Issues'}
              getKeyForRow={this.getKeyForRow}
          />
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
        </Modal>
    }
        </div>;
  }
}

const mapStateToProps = (state) => ({
  HearingWorksheetIssues: state,
  issueDeleteModal: state.issueDeleteModal
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  toggleIssueDeleteModal
}, dispatch);

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(HearingWorksheetIssues);

HearingWorksheetIssues.propTypes = {
  appealKey: PropTypes.number.isRequired,
  worksheetStreamsIssues: PropTypes.array.isRequired,
  worksheetStreamsAppeal: PropTypes.object.isRequired,
  issueDeleteModal: PropTypes.bool.isRequired
};
