import React, { PureComponent } from 'react';
import Table from '../../components/Table';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import _ from 'lodash';
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



    const rowObjects = Object.keys(worksheetIssues).filter((issue, key ) => {

      let issueRow = worksheetIssues[issue];
      // eslint-disable-next-line no-underscore-dangle
      let destroyFilter = issueRow._destroy || issueRow.appeal_id !== worksheetStreamsAppeal.id;
      console.log(issueRow);
      // Deleted issues can't be removed from Redux because we need to send them
      // to the backend with their ID information. We need to filter them from
      // the display.
      return !destroyFilter ? issue : undefined;
    }).map((issue, key) => ({
        counter: <b>{key + 1}.</b>,
        program: <HearingWorksheetIssueFields
          appeal={worksheetStreamsAppeal}
          issue={worksheetIssues[issue]}
          field="program"
        />,
        issue: <HearingWorksheetIssueFields
          appeal={worksheetStreamsAppeal}
          issue={worksheetIssues[issue]}
          field="name"
        />,
        levels: <HearingWorksheetIssueFields
          appeal={worksheetStreamsAppeal}
          issue={worksheetIssues[issue]}
          field="levels"
        />,
        description: <HearingWorksheetIssueFields
          appeal={worksheetStreamsAppeal}
          issue={worksheetIssues[issue]}
          field="description"
        />,
        actions: <HearingWorksheetPreImpressions
          appeal={worksheetStreamsAppeal}
          issue={worksheetIssues[issue]}
        />,
        deleteIssue: <HearingWorksheetIssueDelete
          appeal={worksheetStreamsAppeal}
          issue={worksheetIssues[issue]}
          appealKey={appealKey}
        />
      })
    );

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
