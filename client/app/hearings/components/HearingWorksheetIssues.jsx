import React from 'react';
import Checkbox from '../../components/Checkbox';
import TextField from '../../components/TextField';
import TextareaField from '../../components/TextareaField';
import Table from '../../components/Table';
import { Component } from 'react';

export default class HearingWorksheetIssues extends Component {
  
  getKeyForRow = (index) => {
    return index;
  }

  render()


   {
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
      }
    ];
        // Temp Placeholder issues
    const issues = [
      {
        program: 'Compensation',
        issue: 'Service connection',
        issueID: 101,
        levels: 'All Others, 5010 - Arthritis, due to trauma',
        description: 'Right elbow',
        actions: [
          false, false, false, true, false, false
        ]
      }
    ];

    const rowObjects = issues.map((issue, index) => {
      return {
        counter: <b>{index + 1}.</b>,
        program: issue.program,
        issue: issue.issue,
        issueID: issue.issueID,
        levels: issue.levels,
        description: <div>
          <h4 className="cf-hearings-worksheet-desc-label">Description</h4>
          <TextareaField
            aria-label="Description"
            // TODO Remove placeholder loop | new structure
            // TODO add logic to find specific issue
            name={`issue-${issue.issueID}`}
         //   id={`worksheet-issue-description-${issue.issueID}`}
            value={ ''}
            onChange={this.props}
            />
        </div>,
        actions: <div className="cf-hearings-worksheet-actions">
          <Checkbox
            label="Re-Open"
            name={`chk_reopen_${index}`}
            onChange={() => {
              return true;
            }}
            value={issue.actions[0]}
          ></Checkbox>
          <Checkbox
            label="Allow"
            name={`chk_allow_${index}`}
            onChange={() => {
              return true;
            }}
            value={issue.actions[1]}
          ></Checkbox>
          <Checkbox
            label="Deny"
            name={`chk_deny_${index}`}
            onChange={() => {
              return true;
            }}
            value={issue.actions[2]}
          ></Checkbox>
          <Checkbox
            label="Remand"
            name={`chk_remand_${index}`}
            onChange={() => {
              return true;
            }}
            value={issue.actions[3]}
          ></Checkbox>
          <Checkbox
            label="Dismiss"
            name={`chk_dismiss_${index}`}
            onChange={() => {
              return true;
            }}
            value={issue.actions[4]}
          ></Checkbox>
          <Checkbox
            label="VHA"
            name={`chk_vha_${index}`}
            onChange={() => {
              return true;
            }}
            value={issue.actions[5]}
          ></Checkbox>
        </div>
      };
    });
    return <div className="sub-page">
      <p>lksjd</p>
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