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

    const filteredIssues = filterIssuesOnAppeal(worksheetIssues, worksheetStreamsAppeal.id);

    const rowObjects = Object.keys(filteredIssues).map((issue, key) => {

      let issueRow = worksheetIssues[issue];

      return {
        counter: <b>{key + countOfIssuesInPreviousAppeals + 1}.</b>,
        program: <HearingWorksheetIssueFields
          appeal={worksheetStreamsAppeal}
          issue={issueRow}
          field="program"
          maxLength={30}
        />,
        issue: <HearingWorksheetIssueFields
          appeal={worksheetStreamsAppeal}
          issue={issueRow}
          field="name"
          maxLength={100}
        />,
        levels: <HearingWorksheetIssueFields
          appeal={worksheetStreamsAppeal}
          issue={issueRow}
          field="levels"
          maxLength={100}
        />,
        description: <HearingWorksheetIssueFields
          appeal={worksheetStreamsAppeal}
          issue={issueRow}
          field="description"
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
        summary={'Worksheet Issues'}
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
