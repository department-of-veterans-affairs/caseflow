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
    let { issue, field, from_vacols } = this.props;

    if (field === "program" && from_vacols) {
      return <div>{issue.program}</div>;
    }

    if (field === "program" && !from_vacols) {
      return <div>
          <TextareaField aria-label="Program"
                         id={`${issue.id}-issue`}value={issue.program}
                         onChange={this.onProgramChange}/>
      </div>;
    }

      if (field === "issue" && from_vacols) {
          return <div>{issue.issue}</div>;
      }

      if (field === "issue" && !from_vacols) {
          return <div>
              <TextareaField aria-label="Program"
                         id={`${issue.id}-issue`}value={issue.issue}
                         onChange={this.onIssueChange}/>
          </div>;
      }

      if (field === "levels" && from_vacols) {
          return <div>{issue.levels}</div>;
      }

      if (field === "levels" && !from_vacols) {
          return <div>
              <TextareaField aria-label="Program"
                         id={`${issue.id}-issue`}value={issue.levels}
                         onChange={this.onLevelsChange}/>
          </div>;
      }

    if (field == "description") {
      return <div>
        <TextareaField aria-label="Description" name="Description"
                       id={`${issue.id}-issue`}value={issue.description}
                       onChange={this.onDescriptionChange} maxlength={120} />
      </div>;
    }

    return null;
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

