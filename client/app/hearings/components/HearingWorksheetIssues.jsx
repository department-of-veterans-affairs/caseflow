import React, { PureComponent } from 'react';
import Checkbox from '../../components/Checkbox';
import TextareaField from '../../components/TextareaField';
import Table from '../../components/Table';
import PropTypes from 'prop-types';

class HearingWorksheetIssues extends PureComponent {

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
    // Todo, we still need to loop
    // through issues in a single stream
    const issues = [
      {

      }
    ];

    const rowObjects = issues.map(() => {

      return {
        counter: <b>1.</b>,
        program: worksheetStreamsIssues.program,
        issue: worksheetStreamsIssues.issue,
        levels: worksheetStreamsIssues.levels,
        description: <div>
          <h4 className="cf-hearings-worksheet-desc-label">Description</h4>
          <TextareaField
            aria-label="Description"
            // TODO Update placeholder loop | new structure
            name="Description"
            id={'issue-description'}
            value={worksheetStreamsIssues.description}
            onChange={this.props.onDescriptionChange}
            />
        </div>,
        actions: <div className="cf-hearings-worksheet-actions">
          <Checkbox
            label="Re-Open"
            name={'chk_reopen'}
            onChange={this.props.onToggleReopen}
            value={worksheetStreamsIssues.reopen}
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
