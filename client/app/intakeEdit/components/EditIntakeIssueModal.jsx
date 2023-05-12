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
      mstJustification: '',
      pactJustification: ''
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

  handleMstJustification = (mstJustification) => this.setState({ mstJustification });

  handlePactJustification = (pactJustification) => this.setState({ pactJustification });

  render() {
    const {
      issueIndex,
      onCancel,
      currentIssue = this.props.intakeData.addedIssues[issueIndex],
      currentIssueCategory = currentIssue.category,
      currentIssueDescription = currentIssue.description,
      currentIssueBenefitType = BENEFIT_TYPES[currentIssue.benefitType],
      currentIssueDecisionDate = formatDateStr(currentIssue.decisionDate),
      currentIssueMstChecked = currentIssue.mstChecked,
      currentIssuePactChecked = currentIssue.pactChecked,
      mstIdentification,
      pactIdentification
    } = this.props;

    const { mstChecked, pactChecked, mstJustification, pactJustification } = this.state;

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

              if (this.handleMstCheckboxChange && mstJustification === '') {
                return;
              }
              if (this.handlePactCheckboxChange && pactJustification === '') {
                return;
              }

              this.props.onSubmit({
                currentIssue: {
                  ...currentIssue,
                  mstChecked,
                  pactChecked,
                  mstJustification,
                  pactJustification
                }
              });
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
                    value={this.state.currentIssueMstChecked}
                    onChange={this.handleMstCheckboxChange}
                  />
                }
              </label>
            </li>
          </ul>
          {(mstChecked) && (
            <div>
              <label style={{ paddingLeft: '2em' }}>
                <TextField
                  name={INTAKE_EDIT_ISSUE_CHANGE_MESSAGE}
                  value={this.state.mstJustification}
                  onChange={this.handleMstJustification} />
              </label>
            </div>
          )}
          <ul className="usa-unstyled-list">
            <li>
              <label>
                { pactIdentification &&
                  <Checkbox style={{ marginTop: 0, marginBottom: 0 }}
                    name={PACT_LABEL} strongLabel
                    value={this.state.currentIssuePactChecked}
                    onChange={this.handlePactCheckboxChange}
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
                  value={this.state.pactJustification}
                  onChange={this.handlePactJustification} />
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
    mstJustification: state.mstJustification,
    pactJustification: state.pactJustification
  };
};

const mapDispatchToProps = (dispatch) => {
  return {
    handleMstCheckboxChange: () => dispatch({ type: 'SET_MST_STATUS' }),
    handlePactCheckboxChange: () => dispatch({ type: 'SET_PACT_STATUS' }),
    handleMstJustification: () => dispatch({ type: 'SET_MST_JUSTIFICATION' }),
    handlePactJustification: () => dispatch({ type: 'SET_PACT_JUSTIFICATION' })
  };
};

EditIntakeIssueModal.propTypes = {
  onCancel: PropTypes.func,
  onSubmit: PropTypes.func,
  issueIndex: PropTypes.number,
  mstIdentification: PropTypes.bool,
  pactIdentification: PropTypes.bool,
  mstChecked: PropTypes.bool,
  pactChecked: PropTypes.bool,
  mstJustification: PropTypes.object,
  pactJustification: PropTypes.object,
  intakeData: PropTypes.object,
  currentIssue: PropTypes.object,
  currentIssueCategory: PropTypes.string,
  currentIssueDescription: PropTypes.string,
  currentIssueBenefitType: PropTypes.string,
  currentIssueDecisionDate: PropTypes.string
};

export default connect(mapStateToProps, mapDispatchToProps)(EditIntakeIssueModal);
