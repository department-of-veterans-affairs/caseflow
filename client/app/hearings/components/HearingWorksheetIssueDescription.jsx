import React, { PureComponent } from 'react';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import TextareaField from '../../components/TextareaField';
import { onDescriptionChange } from '../actions/Issue';

class HearingWorksheetIssueDescription extends PureComponent {

  onDescriptionChange = (description) => this.props.onDescriptionChange(description, this.props.issue.id)

  render() {
    let { issue } = this.props;

    return <div>
            <h4 className="cf-hearings-worksheet-desc-label">Description</h4>
            <TextareaField aria-label="Description" name="Description"
              id={issue.id} value={issue.description}
              onChange={this.onDescriptionChange} />
          </div>;
  }
}

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onDescriptionChange
}, dispatch);

const mapStateToProps = (state) => ({
  HearingWorksheetIssueDescription: state
});

HearingWorksheetIssueDescription.propTypes = {
  issue: PropTypes.object.isRequired
};

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(HearingWorksheetIssueDescription);

