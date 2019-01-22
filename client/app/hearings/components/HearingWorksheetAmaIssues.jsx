import React, { PureComponent } from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import Textarea from 'react-textarea-autosize';
import { connect } from 'react-redux';
import { onEditWorksheetNotes } from '../actions/Issue';
import HearingWorksheetPreImpressions from './HearingWorksheetPreImpressions';

class HearingWorksheetAmaIssues extends PureComponent {

  onEditWorksheetNotes = (event) => this.props.onEditWorksheetNotes(event.target.value, this.props.issue.id);

  render() {
    let { issue } = this.props;

    return <div>
      <Textarea aria-label="worksheetNotes"
        name="worksheetNotes"
        id={`${issue.id}-issue-worksheetNotes`}
        value={issue.worksheet_notes || ''}
        onChange={this.onEditWorksheetNotes}
        minRows={2}
        maxRows={8}
        maxLength={300}
      />
      <HearingWorksheetPreImpressions ama issue={issue} />
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

