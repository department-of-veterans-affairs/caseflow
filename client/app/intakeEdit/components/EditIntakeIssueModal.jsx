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
  MST_LABEL,
  PACT_LABEL
} from 'app/../COPY';

export class EditIntakeIssueModal extends React.Component {

  constructor(props) {
    super(props);

    this.state = {
      mstChecked: false,
      pactChecked: false,
      mstReasonNotes: '',
      pactReasonNotes: ''
    };
  }

  handleMstCheckboxChange = () => {
    this.setState((prevState) => ({
      mstChecked: !prevState.mstChecked
    }));
  }

  handlePactCheckboxChange = () => {
    this.setState((prevState) => ({
      pactChecked: !prevState.pactChecked
    }));
  }

  mstReasonNotesChange = (mstReasonNotes) => this.setState({ mstReasonNotes });

  pactReasonNotesChange = (pactReasonNotes) => this.setState({ pactReasonNotes });

  render() {
    const {
      issueIndex,
      onCancel,
      currentIssue = this.props.intakeData.addedIssues[issueIndex],
      currentIssueCategory = currentIssue.category,
      currentIssueDescription = currentIssue.description,
      currentIssueBenefitType = BENEFIT_TYPES[currentIssue.benefitType],
      currentIssueDecisionDate = formatDateStr(currentIssue.decisionDate),
      mstIdentification,
      pactIdentification
    } = this.props;

    const { mstChecked, pactChecked } = this.state;

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
          { currentIssueCategory ? `${currentIssueCategory } - ${ currentIssueDescription}` : currentIssueDescription}
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
                { mstIdentification &&
                  <Checkbox
                    name={MST_LABEL} strongLabel
                    value={mstChecked}
                    onChange={this.handleMstCheckboxChange}
                  />
                }
              </label>
            </li>
          </ul>
          {(mstChecked) && (
            <div>
              <label style={{ 'padding-left': '2em' }}>
                <TextField
                  name={INTAKE_EDIT_ISSUE_CHANGE_MESSAGE}
                  value={this.state.mstReasonNotes}
                  onChange={this.mstReasonNotesChange} />
              </label>
            </div>
          )}
          <ul className="usa-unstyled-list">
            <li>
              <label>
                { pactIdentification &&
                  <Checkbox style={{ 'margin-top': 0, 'margin-bottom': 0 }}
                    name={PACT_LABEL} strongLabel
                    onChange={this.handlePactCheckboxChange}
                    value={pactChecked}
                  />
                }
              </label>
            </li>
          </ul>
          {(pactChecked) && (
            <div>
              <label style={{ 'padding-left': '2em' }}>
                <TextField
                  name={INTAKE_EDIT_ISSUE_CHANGE_MESSAGE}
                  value={this.state.pactReasonNotes}
                  onChange={this.pactReasonNotesChange} />
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
    mstChecked: state.mstChecked,
    pactChecked: state.pactChecked,
    mstReasonNotes: state.mstReasonNotes,
    pactReasonNotes: state.pactReasonNotes
  };
};

const mapDispatchToProps = (dispatch) => {
  return {
    handleMstCheckboxChange: () => dispatch({ type: 'mst_status' }),
    handlePactCheckboxChange: () => dispatch({ type: 'pact_status' }),
    mstReasonNotes: () => dispatch({ type: 'mst_reason_notes' }),
    pactReasonNotes: () => dispatch({ type: 'pact_reason_notes' })
  };
};

EditIntakeIssueModal.propTypes = {
  onCancel: PropTypes.func,
  onSubmit: PropTypes.func,
  issueIndex: PropTypes.number,
  mstIdentification: PropTypes.bool,
  pactIdentification: PropTypes.bool,
  mst_status: PropTypes.func,
  pact_status: PropTypes.func,
  mstCheckboxValue: PropTypes.bool,
  setMstCheckboxFunction: PropTypes.func,
  pactCheckboxValue: PropTypes.bool,
  setPactCheckboxFunction: PropTypes.func,
  mstReasonNotes: PropTypes.object.isRequired,
  pactReasonNotes: PropTypes.object.isRequired,
  intakeData: PropTypes.object,
  currentIssue: PropTypes.object,
  currentIssueCategory: PropTypes.string,
  currentIssueDescription: PropTypes.string,
  currentIssueBenefitType: PropTypes.string,
  currentIssueDecisionDate: PropTypes.string
};

export default connect(mapStateToProps, mapDispatchToProps)(EditIntakeIssueModal);
