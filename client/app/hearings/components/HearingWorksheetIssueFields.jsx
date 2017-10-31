import React, { PureComponent } from 'react';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import Textarea from 'react-textarea-autosize';
import { onProgramChange, onNameChange, onLevelsChange, onDescriptionChange } from '../actions/Issue';

class HearingWorksheetIssueFields extends PureComponent {

  onProgramChange = (event) =>
    this.props.onProgramChange(event.target.value, this.props.issue.id);

  onNameChange = (event) =>
    this.props.onNameChange(event.target.value, this.props.issue.id);

  onLevelsChange = (event) =>
    this.props.onLevelsChange(event.target.value, this.props.issue.id);

  onDescriptionChange = (event) =>
    this.props.onDescriptionChange(event.target.value, this.props.issue.id);

  truncateTextToMaxLength = (string, maxLength) => {
    if (string.length >= maxLength) {
      return string.substring(0, maxLength);
    }

    return string;
  }

  render() {
    let { issue, field, maxLength } = this.props;

    const allowedFields = {
      program: { onChange: this.onProgramChange,
        value: issue.program },
      name: { onChange: this.onNameChange,
        value: issue.name },
      levels: { onChange: this.onLevelsChange,
        value: issue.levels },
      description: { onChange: this.onDescriptionChange,
        value: issue.description,
        alwaysEditable: true }
    };

    if (!allowedFields[field]) {
      console.warn('You called HearingWorksheetIssueFields with an invalid field');

      return;
    }

    if (!issue.from_vacols || allowedFields[field].alwaysEditable) {
      return <div className="cf-form-textarea">
        <label className="cf-hearings-worksheet-desc-label" htmlFor={`${issue.id}-issue-${field}`}>{field}</label>
        <Textarea aria-label={field} name={field}

          id={`${issue.id}-issue-${field}`}
          value={allowedFields[field].value || ''}
          onChange={allowedFields[field].onChange}
          minRows={2}
          maxRows={8}
          maxLength={maxLength}
        />
      </div>;
    }

    return <div id={field}>{this.truncateTextToMaxLength(allowedFields[field].value, maxLength)}</div>;
  }
}

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onProgramChange,
  onNameChange,
  onLevelsChange,
  onDescriptionChange
}, dispatch);

const mapStateToProps = (state) => ({
  HearingWorksheetIssueFields: state
});

HearingWorksheetIssueFields.propTypes = {
  issue: PropTypes.object.isRequired,
  appeal: PropTypes.object.isRequired,
  field: PropTypes.string.isRequired
};

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(HearingWorksheetIssueFields);
