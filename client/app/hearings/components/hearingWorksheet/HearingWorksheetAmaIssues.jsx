import React, { PureComponent } from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import Textarea from 'react-textarea-autosize';
import { css } from 'glamor';
import { connect } from 'react-redux';
import { onEditWorksheetNotes } from '../../actions/hearingWorksheetActions';
import HearingWorksheetPreImpressions from './HearingWorksheetPreImpressions';
import Table from '../../../components/Table';

const tableRowStyling = css({
  '& > tr': {
    '& > td:nth-child(1)': { width: '50%' },
    '& > td:nth-child(2)': { width: '50%' }
  }
});

class HearingWorksheetAmaIssues extends PureComponent {

  onEditWorksheetNotes = (event) => this.props.onEditWorksheetNotes(event.target.value, this.props.issue.id);

  render() {
    let { issue } = this.props;

    const tableColumns = [
      {
        header: 'Hearing Worksheet Notes',
        align: 'left',
        valueName: 'worksheetNotes'
      },
      {
        header: 'Preliminary Impressions',
        align: 'left',
        valueName: 'preliminaryImpressions'
      }
    ];

    const tableRows = [{
      worksheetNotes: <div className="cf-form-textarea">
        <label className="cf-hearings-worksheet-desc-label" htmlFor={`${issue.id}-issue-worksheetNotes`}>
          Worksheet Notes
        </label>
        <div>
          <Textarea
            aria-label="worksheetNotes"
            name="worksheetNotes"
            id={`${issue.id}-issue-worksheetNotes`}
            value={issue.worksheet_notes || ''}
            onChange={this.onEditWorksheetNotes}
            minRows={5}
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
        bodyStyling={tableRowStyling}
        summary="issues"
        slowReRendersAreOk
        borderless
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

