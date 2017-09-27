import React, { PureComponent } from 'react';
import Table from '../../components/Table';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import HearingWorksheetIssueFields from './HearingWorksheetIssueFields';
import HearingWorksheetPreImpressions from './HearingWorksheetPreImpressions';

import { TrashCan } from '../../components/RenderFunctions';

class HearingWorksheetIssues extends PureComponent {

  getKeyForRow = (index) => {
    return index;
  }

  render() {
    let {
     worksheetStreamsIssues,
     worksheetStreamsAppeal
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
            from_vacols={issueRow.from_vacols}
        />,
        issue: <HearingWorksheetIssueFields
            appeal={worksheetStreamsAppeal}
            issue={issueRow}
            field="issue"
            from_vacols={issueRow.from_vacols}
        />,
        levels: <HearingWorksheetIssueFields
            appeal={worksheetStreamsAppeal}
            issue={issueRow}
            field="levels"
            from_vacols={issueRow.from_vacols}
        />,
        description: <HearingWorksheetIssueFields
                      appeal={worksheetStreamsAppeal}
                      issue={issueRow}
                      field="description"
                      from_vacols={issueRow.from_vacols}
                       />,
        actions: <HearingWorksheetPreImpressions
                    appeal={worksheetStreamsAppeal}
                    issue={issueRow} />,
        deleteIssue: <TrashCan />

      };
    });

    return <Table
            className="cf-hearings-worksheet-issues"
            columns={columns}
            rowObjects={rowObjects}
            summary={'Worksheet Issues'}
            getKeyForRow={this.getKeyForRow}
          />;
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
