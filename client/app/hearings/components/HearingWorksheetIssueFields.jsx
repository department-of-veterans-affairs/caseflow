import React, { PureComponent } from 'react';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import Textarea from 'react-textarea-autosize';
import { onProgramChange, onNameChange, onLevelsChange, onIssueNotesChange } from '../actions/Issue';

class HearingWorksheetIssueFields extends PureComponent {

  onProgramChange = (event) =>
    this.props.onProgramChange(event.target.value, this.props.issue.id);

  onNameChange = (event) =>
    this.props.onNameChange(event.target.value, this.props.issue.id);

  onLevelsChange = (event) =>
    this.props.onLevelsChange(event.target.value, this.props.issue.id);

  onIssueNotesChange = (event) =>
    this.props.onIssueNotesChange(event.target.value, this.props.issue.id);

  render() {
    let { issue, field, maxLength } = this.props;

    const allowedFields = {
      program: { onChange: this.onProgramChange,
        value: issue.program },
      name: { onChange: this.onNameChange,
        value: issue.name },
      levels: { onChange: this.onLevelsChange,
        value: issue.levels },
      notes: { onChange: this.onIssueNotesChange,
        value: issue.notes,
        alwaysEditable: true }
    };

    if (!allowedFields[field]) {
      console.warn('You called HearingWorksheetIssueFields with an invalid field');

      return;
    }

    if (!issue.from_vacols || allowedFields[field].alwaysEditable) {
      return <div className="cf-form-textarea">
        <label className="cf-hearings-worksheet-desc-label" htmlFor={`${issue.id}-issue-${field}`}>{field}</label>
        { this.props.readOnly ?
          <p>{allowedFields[field].value}</p> :
          <Textarea aria-label={field} name={field}
            id={`${issue.id}-issue-${field}`}
            value={allowedFields[field].value || ''}
            onChange={allowedFields[field].onChange}
            minRows={2}
            maxRows={8}
            maxLength={maxLength}
          />
        }
      </div>;
    }

    return <div>{allowedFields[field].value}</div>;
  }
}

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onProgramChange,
  onNameChange,
  onLevelsChange,
  onIssueNotesChange
}, dispatch);

const mapStateToProps = (state) => ({
  HearingWorksheetIssueFields: state
});

HearingWorksheetIssueFields.propTypes = {
  issue: PropTypes.object.isRequired,
  appeal: PropTypes.object.isRequired,
  readOnly: PropTypes.bool,
  field: PropTypes.string.isRequired
};

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(HearingWorksheetIssueFields);
