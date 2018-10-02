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
  handleNotesChange(event) {
    this.props.setNotes(this.props.id, event);

  constructor(props) {
    super(props);

    this.state = {
      profileDate: '',
      referenceId: ''
    };
  }

  radioOnChange = (value) => {
    this.setState({
      referenceId: value
    });
  }

  onAddIssue = () => {
    this.props.addIssue(this.state.referenceId, this.props.ratings, true);
    this.props.closeHandler();
  }

  render() {
    let {
      ratings,
      closeHandler
    } = this.props;

    const ratedIssuesSections = _.map(ratings, (rating) => {
      const radioOptions = _.map(rating.issues, (issue) => {
        return {
          displayText: issue.decision_text,
          value: issue.reference_id
        };
      });

      return <RadioField
        vertical
        label={<h3>Past decisions from { formatDateStr(rating.profile_date) }</h3>}
        name={`rating-radio-${rating.profile_date}`}
        options={radioOptions}
        key={rating.profile_date}
        value={this.state.referenceId}
        onChange={this.radioOnChange}
      />;
    });

    return <div>
      <Modal
        buttons={[
          { classNames: ['cf-modal-link', 'cf-btn-link', 'close-modal'],
            name: 'Cancel adding this issue',
            onClick: closeHandler
          },
          { classNames: ['usa-button', 'usa-button-secondary', 'add-issue'],
            name: 'Add Issue',
            onClick: this.onAddIssue
          }
        ]}
        visible
        closeHandler={closeHandler}
        title="Add Issue"
      >
        <div>
          <h2>
            Does this issue match any of these issues from past descriptions?
          </h2>
          <p>
            Tip: sometimes applicants list desired outcome, not what the past decision was
             -- so select the best matching decision.
          </p>
          <br />
          { ratedIssuesSections }
          <br />

          <TextField
            name="Notes"
            value="Hello"
            optional
            onChange={(event) => this.handleNotesChange(event)} />

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
