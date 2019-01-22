import React, { PureComponent } from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import Textarea from 'react-textarea-autosize';
import { connect } from 'react-redux';
import { onEditWorksheetNotes } from '../actions/Issue';
import HearingWorksheetPreImpressions from './HearingWorksheetPreImpressions';
import Table from '../../components/Table';

class HearingWorksheetAmaIssues extends PureComponent {

  onEditWorksheetNotes = (event) => this.props.onEditWorksheetNotes(event.target.value, this.props.issue.id);

  render() {
    let { issue } = this.props;

    const tableColumns = [
      {
        header: 'Hearing Worksheet Notes',
        align: 'center',
        valueName: 'worksheetNotes'
      },
      {
        header: 'Preliminary Impressions',
        align: 'left',
        valueName: 'preliminaryImpressions'
      }
    ];

    const tableRows = [{
      worksheetNotes: <div><label visible={false} htmlFor={`${issue.id}-issue-worksheetNotes`}>Worksheet Notes</label>
        <div>
          <Textarea
            name="worksheetNotes"
            id={`${issue.id}-issue-worksheetNotes`}
            value={issue.worksheet_notes || ''}
            onChange={this.onEditWorksheetNotes}
            minRows={2}
            maxRows={8}
            maxLength={300}
          />
        </div></div>,
      preliminaryImpressions: <HearingWorksheetPreImpressions ama issue={issue} />
    }];

    return <div>
      <Table
        columns={tableColumns}
        rowObjects={tableRows}
        summary="issues"
        slowReRendersAreOk
      />
    </div>;
  }
}

HearingWorksheetAmaIssues.propTypes = {
  issue: PropTypes.object.isRequired
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onEditWorksheetNotes
}, dispatch);

export default connect(
  null,
  mapDispatchToProps
)(HearingWorksheetAmaIssues);

