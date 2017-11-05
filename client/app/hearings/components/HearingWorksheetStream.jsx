import React, { Component } from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import _ from 'lodash';
import Button from '../../components/Button';
import { onAddIssue } from '../actions/Issue';

import HearingWorksheetIssues from './HearingWorksheetIssues';

class HearingWorksheetStream extends Component {

  onAddIssue = (appealId) => () => this.props.onAddIssue(appealId, this.getVacolsSequenceId());

  getMaxVacolsSequenceId = () => {
    let maxValue = 0;

    _.forEach(this.props.worksheetIssues, (issue) => {
      if (Number(issue.vacols_sequence_id) > maxValue) {
        maxValue = Number(issue.vacols_sequence_id);
      }
    });

    return maxValue;
  };

  getVacolsSequenceId = () => {
    return (this.getMaxVacolsSequenceId() + 1).toString();
  };


  render() {

    let {
      worksheetAppeals
    } = this.props;



const WorksheetAppeals = {
'87': {
      id: 87,
      vbms_id: 'b42887f3c',
      nod_date: '2017-10-05T07:23:43.371-04:00',
      soc_date: '2017-10-21T07:23:43.371-04:00',
      certification_date: null,
      prior_decision_date: null,
      form9_date: '2017-10-25T07:23:43.372-04:00',
      docket_number: 4198,
      cached_number_of_documents_after_certification: 0,
      worksheet_issues: [
        {
          id: 7,
          appeal_id: 87,
          vacols_sequence_id: '1',
          reopen: false,
          vha: false,
          allow: false,
          deny: false,
          remand: false,
          dismiss: false,
          program: 'Compensation',
          name: 'Service Connection',
          levels: 'All Others; Thigh, limitation of flexion of',
          description: 'low back condition',
          from_vacols: true,
          deleted_at: null
        },
        {
          id: 8,
          appeal_id: 87,
          vacols_sequence_id: '2',
          reopen: false,
          vha: false,
          allow: false,
          deny: false,
          remand: false,
          dismiss: false,
          program: null,
          name: null,
          levels: null,
          description: null,
          from_vacols: false,
          deleted_at: null
        },
        {
          id: 9,
          appeal_id: 87,
          vacols_sequence_id: '3',
          reopen: false,
          vha: false,
          allow: false,
          deny: false,
          remand: false,
          dismiss: false,
          program: null,
          name: null,
          levels: null,
          description: null,
          from_vacols: false,
          deleted_at: null
        }
      ]
    },

'88': {
      id: 88,
      vbms_id: 'b42887f3c',
      nod_date: '2017-10-05T07:23:43.371-04:00',
      soc_date: '2017-10-21T07:23:43.371-04:00',
      certification_date: null,
      prior_decision_date: null,
      form9_date: '2017-10-25T07:23:43.372-04:00',
      docket_number: 4198,
      cached_number_of_documents_after_certification: 0,
      worksheet_issues: [
        {
          id: 3,
          appeal_id: 88,
          vacols_sequence_id: '18',
          reopen: false,
          vha: false,
          allow: false,
          deny: false,
          remand: false,
          dismiss: false,
          program: 'Compensation',
          name: 'Service Connection',
          levels: 'All Others; Thigh, limitation of flexion of',
          description: 'low back condition',
          from_vacols: true,
          deleted_at: null
        },
        {
          id: 5,
          appeal_id: 88,
          vacols_sequence_id: '27',
          reopen: false,
          vha: false,
          allow: false,
          deny: false,
          remand: false,
          dismiss: false,
          program: null,
          name: null,
          levels: null,
          description: null,
          from_vacols: false,
          deleted_at: null
        },
        {
          id: 5,
          appeal_id: 88,
          vacols_sequence_id: '43',
          reopen: false,
          vha: false,
          allow: false,
          deny: false,
          remand: false,
          dismiss: false,
          program: null,
          name: null,
          levels: null,
          description: null,
          from_vacols: false,
          deleted_at: null
        }
      ]
    }
  };




class IssueCounter extends Component {
  render() {
    const arr = [];
    let appealNumber = 1;
    let issueStartWith = 0;

    Object.keys(WorksheetAppeals).forEach(key => {
      arr.push({
        issue: WorksheetAppeals[key],
        appealNumber,
        issueStartWith,
      });
      appealNumber += 1;
      issueStartWith += Object.keys(WorksheetAppeals[key]).length;
    });

    return (
      <div className="cf-hearings-worksheet-data">
            <h2 className="cf-hearings-worksheet-header">Issues</h2>
        {
          arr.map(issue =>

            <ApealStream
              issue={issue.issue}
              issueNumber={issue.appealNumber}
              issueStartWith={issue.issueStartWith}
              key={issue.appealNumber}
            />
          )
        }
      </div>
    )
  }
}

    return <IssueCounter />;
  }
}


class ApealStream extends Component {


  render() {

        let {
      worksheetAppeals
    } = this.props;
    console.log(this.props.issue.worksheet_issues);
    return (
      <div>

        <p>APPEAL STREAM {this.props.issueNumber}</p>
   
     

   <HearingWorksheetIssues
            appealKey={87}
            worksheetStreamsAppeal={worksheetAppeals}
            issueIndex={this.props.issueStartWith}
            {...this.props}
          />

          <Button
            classNames={['usa-button-outline', 'hearings-add-issue']}
            name="+ Add Issue"
            
         
          />
          <hr />
        </div>
    );
  }
}

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onAddIssue
}, dispatch);

const mapStateToProps = (state) => ({
  worksheetAppeals: state.worksheetAppeals
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(HearingWorksheetStream);
