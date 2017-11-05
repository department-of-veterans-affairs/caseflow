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
      issueIndex,
      appealKey
    } = this.props;

    console.log(appealKey);



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
    // // to the backend with their ID information. We filter them from the display.
    // const filteredIssues = _.pickBy(worksheetIssues, (issue) => {
    //   // eslint-disable-next-line no-underscore-dangle
    //   return !issue._destroy && issue.appeal_id === worksheetStreamsAppeal.id;
    // });

    const rowObjects = Object.keys(worksheetIssues).map((issue, key) => {

      let issueRow = worksheetIssues[issue];

      return {
        counter: <b>{issueIndex + key + 1}.</b>
        
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
  worksheetStreamsAppeal: PropTypes.object,
  issueIndex: PropTypes.number.isRequired
};
