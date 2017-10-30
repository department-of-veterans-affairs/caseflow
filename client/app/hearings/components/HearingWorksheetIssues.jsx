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
      appealKey
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

    // Deleted issues can't be removed from Redux because we need to send them
    // to the backend with their ID information. Ww filter them from the display.
    /* eslint-disable */
    const filteredIssues = Object.entries(worksheetIssues).filter(([key, value]) => !value._destroy).
      reduce((obj, [key, value]) => (obj[key] = value) && obj, {});
    /* eslint-enable */

    const rowObjects = Object.keys(filteredIssues).map((issue, key) => {

      let issueRow = worksheetIssues[issue];

      return {
        counter: <b>{key + 1}.</b>,
        program: <HearingWorksheetIssueFields
          appeal={worksheetStreamsAppeal}
          issue={issueRow}
          field="program"
        />,
        issue: <HearingWorksheetIssueFields
          appeal={worksheetStreamsAppeal}
          issue={issueRow}
          field="name"
        />,
        levels: <HearingWorksheetIssueFields
          appeal={worksheetStreamsAppeal}
          issue={issueRow}
          field="levels"
        />,
        description: <HearingWorksheetIssueFields
          appeal={worksheetStreamsAppeal}
          issue={issueRow}
          field="description"
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
  worksheetStreamsAppeal: PropTypes.object.isRequired
};
