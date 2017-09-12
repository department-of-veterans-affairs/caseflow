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

    // Maps over all issues inside stream
    const rowObjects = Object.keys(worksheetStreamsIssues).map((issue, key) => {

      return {
        counter: <b>{key + 1}.</b>,
        program: worksheetStreamsIssues[issue].program,
        issue: worksheetStreamsIssues[issue].issue,
        levels: worksheetStreamsIssues[issue].levels,
        description: <div>
          <h4 className="cf-hearings-worksheet-desc-label">Description</h4>
          <TextareaField
            aria-label="Description"
            name="Description"
            id={'issue-description'}
            value={worksheetStreamsIssues[issue].description}
            onChange={this.props.onDescriptionChange}
            />
        </div>,
        actions: <div className="cf-hearings-worksheet-actions">
          <Checkbox label="Re-Open" name={ 'chk_reopen'}
            onChange={this.props.onToggleReopen}
            value={worksheetStreamsIssues[issue].reopen}>
          </Checkbox>
          <Checkbox label="Allow" name={ 'chk_allow'}
            onChange={this.props.onToggleAllow}
            value={worksheetStreamsIssues[issue].allow}>
          </Checkbox>
          <Checkbox label="Deny" name={ 'chk_deny'}
            onChange={this.props.onToggleDeny}
            value={worksheetStreamsIssues[issue].deny}>
          </Checkbox>
          <Checkbox label="Remand" name={ 'chk_remand'}
            onChange={this.props.onToggleRemand}
            value={worksheetStreamsIssues[issue].remand}>
          </Checkbox>
          <Checkbox label="Dismiss" name={ 'chk_dismiss'}
            onChange={this.props.onToggleDismiss}
            value={worksheetStreamsIssues[issue].dismiss}>
          </Checkbox>
          <Checkbox label="VHA" name={ 'chk_vha'}
            onChange={this.props.onToggleVHA}
            value={worksheetStreamsIssues[issue].vha}>
          </Checkbox>
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
