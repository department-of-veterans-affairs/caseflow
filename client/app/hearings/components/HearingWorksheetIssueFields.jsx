import React, { PureComponent } from 'react';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import TextareaField from '../../components/TextareaField';
import { onProgramChange, onIssueChange, onLevelsChange, onDescriptionChange } from '../actions/Issue';

class HearingWorksheetIssueFields extends PureComponent {

  onProgramChange = (program) =>
    this.props.onProgramChange(program, this.props.issue.id, this.props.appeal.id);

  onIssueChange = (issue) =>
    this.props.onIssueChange(issue, this.props.issue.id, this.props.appeal.id);

  onLevelsChange = (levels) =>
    this.props.onLevelsChange(levels, this.props.issue.id, this.props.appeal.id);

  onDescriptionChange = (description) =>
    this.props.onDescriptionChange(description, this.props.issue.id, this.props.appeal.id)

  render() {
    let { issue, field } = this.props;

    const allowedFields = {
      program: { onChange: this.onProgramChange,
        value: issue.program },
      issue: { onChange: this.onIssueChange,
        value: issue.issue },
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
      return <div> <TextareaField aria-label={field} name={field}
                                    id={`${issue.id}-issue`}value={allowedFields[field].value}
                                    onChange={allowedFields[field].onChange}/>
      </div>;
    }

    return <div>{allowedFields[field].value}</div>;
  }
}

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onProgramChange,
  onIssueChange,
  onLevelsChange,
  onDescriptionChange
}, dispatch);

const mapStateToProps = (state) => ({
  HearingWorksheetIssueFields: state
});

HearingWorksheetIssueFields.propTypes = {
  issue: PropTypes.object.isRequired,
  appeal: PropTypes.object.isRequired
};

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(HearingWorksheetIssueFields);

