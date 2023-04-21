import React from 'react';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import Modal from 'app/components/Modal';
import Checkbox from '../../components/Checkbox';
import TextField from '../../components/TextField';
import BENEFIT_TYPES from '../../../constants/BENEFIT_TYPES.json';
import { formatDateStr } from '../../util/DateUtil';
import {
  INTAKE_EDIT_ISSUE_TITLE,
  INTAKE_EDIT_ISSUE_SELECT_SPECIAL_ISSUES,
  INTAKE_EDIT_ISSUE_CHANGE_MESSAGE,
  INTAKE_EDIT_ISSUE_LABEL,
  INTAKE_EDIT_ISSUE_BENEFIT_TYPE,
  INTAKE_EDIT_ISSUE_DECISION_DATE,
  INTAKE_EDIT_ISSUE_MST_LABEL,
  INTAKE_EDIT_ISSUE_PACT_LABEL
} from 'app/../COPY';

export class EditIntakeIssueModal extends React.Component {

  constructor(props) {
    super(props);

    this.state = {
      mstCheckboxValue: false,
      pactCheckboxValue: false,
      reasonNotes: '',
    };
  }

  handleMstCheckboxChange = () => {
    this.setState(prevState => ({
      mstCheckboxValue: !prevState.mstCheckboxValue
    }));
  }

  handlePactCheckboxChange = () => {
    this.setState(prevState => ({
      pactCheckboxValue: !prevState.pactCheckboxValue
    }));
  }

  reasonNotesOnChange = (reasonNotes) => this.setState({ reasonNotes });

  render() {
    const {
      issueIndex,
      onCancel,
      currentIssue = this.props.intakeData.addedIssues[issueIndex],
      currentIssueCategory = currentIssue.category,
      currentIssueDescription = currentIssue.description,
      currentIssueBenefitType = BENEFIT_TYPES[currentIssue.benefitType],
      currentIssueDecisionDate = formatDateStr(currentIssue.decisionDate),
    } = this.props;

    const { mstCheckboxValue, pactCheckboxValue } = this.state;

    return <div className="edit-intake-issue">
      <Modal
        buttons={[
          { classNames: ['cf-modal-link', 'cf-btn-link', 'close-modal'],
            name: 'Cancel',
            onClick: this.props.onCancel
          },
          { classNames: ['usa-button-blue', 'save-issue'],
            name: 'Save',
            onClick: () => {
              this.props.onSubmit();
            //  this.props.mstUpdate(mst_status);
            //  this.props.pactUpdate(pact_status);
            }
          }
        ]}
        visible
        closeHandler={onCancel}
        title={INTAKE_EDIT_ISSUE_TITLE}
      >
        <div>
          <strong>
            { INTAKE_EDIT_ISSUE_LABEL }
          </strong>
          { currentIssueCategory ? currentIssueCategory + " - " + currentIssueDescription : currentIssueDescription}
        </div>

        <div>
          <strong>
            { currentIssueBenefitType ? INTAKE_EDIT_ISSUE_BENEFIT_TYPE : null }
          </strong>
          { currentIssueBenefitType ? currentIssueBenefitType : null }
        </div>

        <div>
          <strong>
            { INTAKE_EDIT_ISSUE_DECISION_DATE }
          </strong>
          { currentIssueDecisionDate }
        </div>
        <br></br>
        <p>{ INTAKE_EDIT_ISSUE_SELECT_SPECIAL_ISSUES }</p>
        <fieldset className="usa-fieldset-inputs usa-sans">
          <legend className="usa-sr-only">MST PACT STATUS</legend>
          <ul className="usa-unstyled-list">
            <li>
              <label>
                <Checkbox
                  name={INTAKE_EDIT_ISSUE_MST_LABEL} strongLabel
                  onChange={this.handleMstCheckboxChange}
                  value={mstCheckboxValue}
                />
              </label>
            </li>
            <li>
              <label>
                <Checkbox style={{ 'margin-top': 0, 'margin-bottom': 0 }}
                  name={INTAKE_EDIT_ISSUE_PACT_LABEL} strongLabel
                  onChange={this.handlePactCheckboxChange}
                  value={pactCheckboxValue}
                />
              </label>
            </li>
          </ul>
          {(mstCheckboxValue || pactCheckboxValue) && (
            <div>
              <label style={{ 'padding-left': '2em' }}>
                <TextField
                  name={INTAKE_EDIT_ISSUE_CHANGE_MESSAGE}
                  value={this.state.reasonNotes}
                  optional
                  onChange={this.reasonNotesOnChange} />
              </label>
            </div>
          )}
        </fieldset>

      </Modal>
    </div>;
  }
}

const mapStateToProps = (state) => {
  return {
    mstCheckboxValue: state.mstCheckboxValue,
    pactCheckboxValue: state.pactCheckboxValue
  };
};

const mapDispatchToProps = (dispatch) => {
  return {
    handleMstCheckboxChange: () => dispatch({ type: 'TOGGLE_MSTCHECKBOXVALUE' }),
    handlePactCheckboxChange: () => dispatch({ type: 'TOGGLE_PACTCHECKBOXVALUE' })
  };
};

EditIntakeIssueModal.propTypes = {
  onCancel: PropTypes.func,
  onSubmit: PropTypes.func,
  issueIndex: PropTypes.number,
  mst_status: PropTypes.func,
  pact_status: PropTypes.func,
  mstCheckboxValue: PropTypes.bool,
  setMstCheckboxFunction: PropTypes.func,
  pactCheckboxValue: PropTypes.bool,
  setPactCheckboxFunction: PropTypes.func,
};

export default connect(mapStateToProps, mapDispatchToProps)(EditIntakeIssueModal);
