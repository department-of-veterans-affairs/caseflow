import React, { PureComponent } from 'react';
import Table from '../../components/Table';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import HearingWorksheetIssueFields from './HearingWorksheetIssueFields';
import HearingWorksheetPreImpressions from './HearingWorksheetPreImpressions';
import HearingWorksheetIssueDelete from './HearingWorksheetIssueDelete';
import HearingWorksheetIssueCounter from './HearingWorksheetIssueCounter';

class HearingWorksheetIssues extends PureComponent {

  getKeyForRow = (index) => index;

  render() {
    let {
      worksheetStreamsIssues,
      worksheetStreamsAppeal,
      appealKey,
      issueCounter
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

      // Deleted issues can't be removed from Redux because we need to send them
      // to the backend with their ID information. We need to filter them from
      // the display.
      // eslint-disable-next-line no-underscore-dangle
      if (issueRow._destroy) {
        return {};
      }

      return {
        counter: <HearingWorksheetIssueCounter
                  issueCounter={issueCounter + key}
         />,
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
        deleteIssue: <HearingWorksheetIssueDelete
                    appeal={worksheetStreamsAppeal}
                    issue={issueRow}
                    appealKey={appealKey}
                    issueKey={key}
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
  HearingWorksheetIssues: state
});


export default connect(
  mapStateToProps,
)(HearingWorksheetIssues);

HearingWorksheetIssues.propTypes = {
  appealKey: PropTypes.number.isRequired,
  issueCounter: PropTypes.number.isRequired,
  worksheetStreamsIssues: PropTypes.array.isRequired,
  worksheetStreamsAppeal: PropTypes.object.isRequired
};
