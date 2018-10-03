import _ from 'lodash';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import React from 'react';

import { addNonRatedIssue } from '../actions/ama';
import Modal from '../../components/Modal';
import SearchableDropdown from '../../components/SearchableDropdown';
import TextField from '../../components/TextField';
import Button from '../../components/Button';
import DateSelector from '../../components/DateSelector';
import { NON_RATED_ISSUE_CATEGORIES } from '../../intakeCommon/constants';

class NonRatedIssueModal extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      category: '',
      description: 'hello',
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
    this.props.addNonRatedIssue(this.state.category, this.props.description, this.props.decisionDate);
    this.props.closeHandler();
  }

  render() {
    let {
      closeHandler
    } = this.props;

    const { category, description, decisionDate } = this.state;
    const requiredFieldsMissing = !description || !category || !decisionDate

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
            disabled: requiredFieldsMissing
          }
        ]}
        visible
        closeHandler={closeHandler}
        title="Add Issue"
      >
        <div>
          <h2>
            Does this issue match any of these issue categories?
          </h2>

          <SearchableDropdown
            name="issue-category"
            label="Issue category"
            placeholder="Select or enter..."
            options={NON_RATED_ISSUE_CATEGORIES}
            value={category}
            onChange={this.categoryOnChange} />

          <TextField
            name="Issue description"
            value={description}
            onChange={this.descriptionOnChange} />

          <DateSelector
            name="Issue date"
            label="Decision date"
            value={decisionDate}
            onChange={this.decisionDateOnChange} />
        </div>
      </Modal>
    </div>;
  }
}

export default connect(
  null,
  (dispatch) => bindActionCreators({
    addNonRatedIssue
  }, dispatch)
)(NonRatedIssueModal);
