import React, { PureComponent } from 'react';
import Table from '../../components/Table';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import HearingWorksheetIssueFields from './HearingWorksheetIssueFields';
import HearingWorksheetPreImpressions from './HearingWorksheetPreImpressions';
import HearingWorksheetIssueDelete from './HearingWorksheetIssueDelete';

class HearingWorksheetIssues extends PureComponent {

  getKeyForRow = (index) => index;

  render() {
    let {
      worksheetIssues,
      worksheetStreamsAppeal,
      appealKey,
      countOfIssuesInPreviousAppeals
    } = this.props;

    const columns = [
      {
        header: '',
        valueName: 'counter'
      },
      {
        header: `Appeal Stream ${appealKey + 1}`,
        align: 'left',
        valueName: 'description'
      },
      {
        header: 'Notes',
        align: 'left',
        valueName: 'notes'
      },
      {
        header: 'Disposition',
        align: 'left',
        valueName: 'disposition'
      }
    ];

    if (!this.props.prior) {
      columns.push({
        header: 'Preliminary Impressions',
        align: 'left',
        valueName: 'actions'
      });
    }

    if (!this.props.print && !this.props.prior) {
      columns.push({
        header: '',
        align: 'left',
        valueName: 'deleteIssue'
      });
    }

    const rowObjects = Object.keys(this.props.issues).map((issue, key) => {

      let issueRow = worksheetIssues[issue];

      return {
        counter: <b>{key + countOfIssuesInPreviousAppeals + 1}.</b>,
        description: <HearingWorksheetIssueFields
          appeal={worksheetStreamsAppeal}
          issue={issueRow}
          field="description"
          maxLength={200}
        />,
        notes: <HearingWorksheetIssueFields
          appeal={worksheetStreamsAppeal}
          issue={issueRow}
          field="notes"
          readOnly={this.props.print || this.props.prior}
          maxLength={100}
        />,
        disposition: <HearingWorksheetIssueFields
          appeal={worksheetStreamsAppeal}
          issue={issueRow}
          field="disposition"
          maxLength={100}
        />,
        actions: <HearingWorksheetPreImpressions
          appeal={worksheetStreamsAppeal}
          issue={issueRow}
        />,
        deleteIssue: <HearingWorksheetIssueDelete
          appeal={worksheetStreamsAppeal}
          issue={issueRow}
          appealKey={appealKey}
        />
      };
    });

    return <div>
      <Table
        className="cf-hearings-worksheet-issues"
        columns={columns}
        rowObjects={rowObjects}
        summary="Worksheet Issues"
        getKeyForRow={this.getKeyForRow}
      />
    </div>;
  }
}

const mapStateToProps = (state) => ({
  worksheetIssues: state.worksheetIssues
});

export default connect(
  mapStateToProps,
)(HearingWorksheetIssues);

HearingWorksheetIssues.propTypes = {
  appealKey: PropTypes.number.isRequired,
  issues: PropTypes.object.isRequired,
  prior: PropTypes.bool,
  worksheetStreamsAppeal: PropTypes.object.isRequired,
  countOfIssuesInPreviousAppeals: PropTypes.number.isRequired
};
