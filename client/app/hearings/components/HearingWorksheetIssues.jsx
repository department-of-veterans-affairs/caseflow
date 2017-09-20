import React, { PureComponent } from 'react';
import Table from '../../components/Table';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import HearingWorksheetIssueFields from './HearingWorksheetIssueFields';
import HearingWorksheetPreImpressions from './HearingWorksheetPreImpressions';
import Modal from '../../components/Modal';

import { TrashCan } from '../../components/RenderFunctions';

class HearingWorksheetIssues extends PureComponent {

  constructor(props) {
      super(props);
      window.jqueryOn = false;

      this.state = {
        modal: false,
        value: ''
      };
    }

    handleModalOpen = () => {
      this.setState({ modal: true });
    };

    handleModalClose = () => {
      this.setState({ modal: false });
    };

  render() {
    let {
     worksheetStreamsIssues,
     worksheetStreamsAppeal
    } = this.props;

    let modal = this.state.modal;

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
        program: issueRow.program,
        issue: issueRow.issue,
        levels: issueRow.levels,
        description: <HearingWorksheetIssueFields
                      appeal={worksheetStreamsAppeal}
                      issue={issueRow}
                       />,
        actions: <HearingWorksheetPreImpressions
                    appeal={worksheetStreamsAppeal}
                    issue={issueRow} />,
        deleteIssue: <TrashCan   onClick={this.handleModalOpen} />,

      };
    });

    return <div>
     <Modal
        buttons = {[
          { classNames: ['cf-modal-link', 'cf-btn-link'],
            name: 'Close',
            onClick: this.handleModalClose
          },
          { classNames: ['usa-button', 'usa-button-primary'],
            name: 'Yes',
            onClick: this.handleModalClose
          }
        ]}
        closeHandler={this.handleModalClose}
        title = "Remove Issue Row">
        <p>Are you sure you want to remove this issue from Appeal Stream 1 on the worksheet? <br />
        This issue will be removed from the worksheet, but will remain in VACOLS</p>
      </Modal>

    <Table
            className="cf-hearings-worksheet-issues"
            columns={columns}
            rowObjects={rowObjects}
            summary={'Worksheet Issues'}
            getKeyForRow={this.getKeyForRow}
          /></div>;
  }
}

const mapStateToProps = (state) => ({
  HearingWorksheetIssues: state
});

export default connect(
  mapStateToProps
)(HearingWorksheetIssues);

HearingWorksheetIssues.propTypes = {
  worksheetStreamsIssues: PropTypes.object.isRequired,
  worksheetStreamsAppeal: PropTypes.object.isRequired
};
