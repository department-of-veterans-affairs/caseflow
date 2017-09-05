import React, { Component } from 'react';
import Checkbox from '../../components/Checkbox';
import TextareaField from '../../components/TextareaField';
import Table from '../../components/Table';
import PropTypes from 'prop-types';

class HearingWorksheetIssues extends Component {

  getKeyForRow = (index) => {
    return index;
  }

  render() {
    let {
     worksheetStreamsIssues
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
      }
    ];
    // Temp Placeholder issues
    const issues = [
      {
        program: worksheetStreamsIssues.program,
        issue: 'Service connection',
        levels: 'All Others, 5010 - Arthritis, due to trauma',
        description: worksheetStreamsIssues.description,
        reopen: true,
        remand: true,
        allow: true,
        dismiss: true,
        deny: true,
        vha: true
      }
    ];

    const rowObjects = issues.map((issue) => {

      return {
        counter: <b>1.</b>,
        program: issue.program,
        issue: issue.issue,
        issueID: issue.issueID,
        levels: issue.levels,
        description: <div>
          <h4 className="cf-hearings-worksheet-desc-label">Description</h4>
          <TextareaField
            aria-label="Description"
            // TODO Update placeholder loop | new structure
            name="Description"
            id={'issue-description'}
            value={issue.description}
            onChange={this.props.onDescriptionChange}
            />
        </div>,
        actions: <div className="cf-hearings-worksheet-actions">
          <Checkbox
            label="Re-Open"
            name={'chk_reopen'}
             onChange={() => {
               return true;
             }}

            value={issues.reopen}
          ></Checkbox>
          <Checkbox
            label="Allow"
            name={'chk_allow'}
            onChange={() => {
              return true;
            }}
            value={issues.allow}
          ></Checkbox>
          <Checkbox
            label="Deny"
            name={'chk_deny'}
            onChange={() => {
              return true;
            }}
            value={issues.deny}
          ></Checkbox>
          <Checkbox
            label="Remand"
            name={'chk_remand'}
            onChange={() => {
              return true;
            }}
            value={issues.remand}
          ></Checkbox>
          <Checkbox
            label="Dismiss"
            name={'chk_dismiss'}
            onChange={() => {
              return true;
            }}
            value={issues.dismiss}
          ></Checkbox>
          <Checkbox
            label="VHA"
            name={'chk_vha'}
            onChange={() => {
              return true;
            }}
            value={issues.vha}
          ></Checkbox>
        </div>
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


HearingWorksheetIssues.propTypes = {
  worksheetStreamsIssues: PropTypes.object.isRequired
};

export default HearingWorksheetIssues;

