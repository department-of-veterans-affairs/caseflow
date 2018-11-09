import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import React from 'react';

import { addNonratingRequestIssue, toggleUnidentifiedIssuesModal } from '../actions/addIssues';
import Modal from '../../components/Modal';
import SearchableDropdown from '../../components/SearchableDropdown';
import TextField from '../../components/TextField';
import DateSelector from '../../components/DateSelector';
import { NONRATING_REQUEST_ISSUE_CATEGORIES } from '../constants';

class NonratingRequestIssueModal extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      category: '',
      description: '',
      decisionDate: ''
    };
  }

  categoryOnChange = (value) => {
    this.setState({
      category: value
    });
  }

  descriptionOnChange = (value) => {
    this.setState({
      description: value
    });
  }

  decisionDateOnChange = (value) => {
    this.setState({
      decisionDate: value
    });
  }

  onAddIssue = () => {
    this.props.addNonratingRequestIssue(
      this.state.category.value,
      this.state.description,
      this.state.decisionDate
    );
    this.props.closeHandler();
  }

  render() {
    let {
      intakeData,
      closeHandler
    } = this.props;

    const { category, description, decisionDate } = this.state;
    const issueNumber = (intakeData.addedIssues || []).length + 1;
    const requiredFieldsMissing = !description || !category || !decisionDate;

    return <div className="intake-add-issues">
      <Modal
        buttons={[
          { classNames: ['cf-modal-link', 'cf-btn-link', 'close-modal'],
            name: 'Cancel adding this issue',
            onClick: closeHandler
          },
          { classNames: ['usa-button', 'add-issue'],
            name: 'Add this issue',
            onClick: this.onAddIssue,
            disabled: requiredFieldsMissing
          },
          { classNames: ['usa-button', 'usa-button-secondary', 'no-matching-issues'],
            name: 'None of these match, see more options',
            onClick: this.props.toggleUnidentifiedIssuesModal
          }
        ]}
        visible
        closeHandler={closeHandler}
        title={`Add issue ${issueNumber}`}
      >
        <div>
          <h2>
            Does issue {issueNumber} match any of these issue categories?
          </h2>
          <div className="add-nonrating-request-issue">
            <SearchableDropdown
              name="issue-category"
              label="Issue category"
              strongLabel
              placeholder="Select or enter..."
              options={NONRATING_REQUEST_ISSUE_CATEGORIES}
              value={category}
              onChange={this.categoryOnChange} />

            <div className="decision-date">
              <DateSelector
                name="decision-date"
                label="Decision date"
                strongLabel
                value={decisionDate}
                onChange={this.decisionDateOnChange} />
            </div>

            <TextField
              name="Issue description"
              strongLabel
              value={description}
              onChange={this.descriptionOnChange} />
          </div>
        </div>
      </Modal>
    </div>;
  }
}

export default connect(
  null,
  (dispatch) => bindActionCreators({
    addNonratingRequestIssue,
    toggleUnidentifiedIssuesModal
  }, dispatch)
)(NonratingRequestIssueModal);
