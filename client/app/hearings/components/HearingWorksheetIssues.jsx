import React, { PureComponent } from 'react';
import Table from '../../components/Table';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import HearingWorksheetIssueFields from './HearingWorksheetIssueFields';
import HearingWorksheetPreImpressions from './HearingWorksheetPreImpressions';
import HearingWorksheetIssueDelete from './HearingWorksheetIssueDelete';
import { filterIssuesOnAppeal } from '../util/IssuesUtil';

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
        header: 'Description',
        align: 'left',
        valueName: 'description'
      },
      {
        header: 'Notes',
        align: 'left',
        valueName: 'notes'
      },
      {
        header: 'Preliminary Impressions',
        align: 'left',
        valueName: 'actions'
      }
    ];

    if (!this.props.print) {
      columns.push({
        header: '',
        align: 'left',
        valueName: 'deleteIssue'
      });
    }

    const filteredIssues = filterIssuesOnAppeal(worksheetIssues, worksheetStreamsAppeal.id);

    const rowObjects = Object.keys(filteredIssues).map((issue, key) => {

      let issueRow = worksheetIssues[issue];

      return {
        counter: <b>{key + countOfIssuesInPreviousAppeals + 1}.</b>,
        description: <HearingWorksheetIssueFields
          appeal={worksheetStreamsAppeal}
          issue={issueRow}
          field="description"
          readOnly={this.props.print}
          maxLength={100}
        />,
        notes: <HearingWorksheetIssueFields
          appeal={worksheetStreamsAppeal}
          issue={issueRow}
          field="notes"
          readOnly={this.props.print}
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
  worksheetStreamsAppeal: PropTypes.object.isRequired,
  countOfIssuesInPreviousAppeals: PropTypes.number.isRequired
};
