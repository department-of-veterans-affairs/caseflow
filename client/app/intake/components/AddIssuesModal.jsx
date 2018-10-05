import _ from 'lodash';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import React from 'react';

import { addIssue } from '../actions/ama';
import { formatDateStr } from '../../util/DateUtil';
import Modal from '../../components/Modal';
import RadioField from '../../components/RadioField';
import TextField from '../../components/TextField';

class AddIssuesModal extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      profileDate: '',
      referenceId: '',
      notes: ''
    };
  }

  radioOnChange = (value) => {
    this.setState({
      referenceId: value
    });
  }

  notesOnChange = (value) => {
    this.setState({
      notes: value
    });
  }

  onAddIssue = () => {
    this.props.addIssue(this.state.referenceId, this.props.intakeData.ratings, true, this.state.notes);
    this.props.closeHandler();
  }

  render() {
    let {
      intakeData,
      closeHandler
    } = this.props;

    const addedIssues = intakeData.addedIssues ? intakeData.addedIssues : [];
    const ratedIssuesSections = _.map(intakeData.ratings, (rating) => {
      const radioOptions = _.map(rating.issues, (issue) => {
        const foundIndex = addedIssues.map((addedIssue) => addedIssue.id).indexOf(issue.reference_id);
        const text = foundIndex === -1 ?
          issue.decision_text :
          `${issue.decision_text} (already selected for issue ${foundIndex + 1})`;

        return {
          displayText: text,
          value: issue.reference_id,
          disabled: foundIndex !== -1
        };
      });

      return <RadioField
        vertical
        label={<h3>Past decisions from { formatDateStr(rating.profile_date) }</h3>}
        name="rating-radio"
        options={radioOptions}
        key={rating.profile_date}
        value={this.state.referenceId}
        onChange={this.radioOnChange}
      />;
    });

    const issueNumber = (intakeData.addedIssues || []).length + 1;

    return <div>
      <Modal
        buttons={[
          { classNames: ['cf-modal-link', 'cf-btn-link', 'close-modal'],
            name: 'Cancel adding this issue',
            onClick: closeHandler
          },
          { classNames: ['usa-button', 'usa-button-secondary', 'add-issue'],
            name: 'Add Issue',
            onClick: this.onAddIssue,
            disabled: !this.state.referenceId
          }
        ]}
        visible
        closeHandler={closeHandler}
        title={`Add issue ${issueNumber}`}
      >
        <div>
          <h2>
            Does issue {issueNumber} match any of these issues from past descriptions?
          </h2>
          <p>
            Tip: sometimes applicants list desired outcome, not what the past decision was
             -- so select the best matching decision.
          </p>
          <br />
          { ratedIssuesSections }
          <TextField
            name="Notes"
            value={this.state.notes}
            optional
            strongLabel
            onChange={this.notesOnChange} />
        </div>
      </Modal>
    </div>;
  }
}

export default connect(
  null,
  (dispatch) => bindActionCreators({
    addIssue
  }, dispatch)
)(AddIssuesModal);
