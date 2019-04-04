import React from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import _ from 'lodash';
import { css } from 'glamor';

import Button from '../components/Button';
import IssueAma from '../components/IssueAma';
import DecisionIssues from './components/DecisionIssues';
import SelectIssueDispositionDropdown from './components/SelectIssueDispositionDropdown';
import Modal from '../components/Modal';
import TextareaField from '../components/TextareaField';
import SearchableDropdown from '../components/SearchableDropdown';
// import ContestedIssues, { contestedIssueStyling } from './components/ContestedIssues';
import COPY from '../../COPY.json';
import { COLORS } from '../constants/AppConstants';

import {
  setDecisionOptions,
  editStagedAppeal
} from './QueueActions';
import { hideSuccessMessage } from './uiReducer/uiActions';
import {
  PAGE_TITLES,
  VACOLS_DISPOSITIONS,
  ISSUE_DISPOSITIONS
} from './constants';
import USER_ROLE_TYPES from '../../constants/USER_ROLE_TYPES.json';

import BENEFIT_TYPES from '../../constants/BENEFIT_TYPES.json';
import DIAGNOSTIC_CODE_DESCRIPTIONS from '../../constants/DIAGNOSTIC_CODE_DESCRIPTIONS.json';
import uuid from 'uuid';
import QueueFlowPage from './components/QueueFlowPage';

const connectedIssueDiv = css({
  display: 'flex',
  justifyContent: 'space-between',
  marginBottom: '10px'
});

const paragraphH3SiblingStyle = css({ marginTop: '0px !important' });

const exampleDiv = css({
  color: COLORS.GREY,
  fontStyle: 'Italic'
});

const textAreaStyle = css({
  maxWidth: '100%'
});

class SelectDispositionsView extends React.PureComponent {
  constructor(props) {
    super(props);

    this.state = {
      openRequestIssueId: null,
      decisionIssue: null,
      editingExistingIssue: false,
      highlightModal: false,
      deleteAddedDecisionIssue: null
    };
  }

  componentDidMount = () => {
    if (this.props.userRole === USER_ROLE_TYPES.attorney) {
      this.props.setDecisionOptions({ work_product: 'Decision' });
    }
  }

  getPageName = () => PAGE_TITLES.DISPOSITIONS[this.props.userRole.toUpperCase()];

  getNextStepUrl = () => {
    const {
      appealId,
      taskId,
      checkoutFlow,
      userRole,
      appeal: { decisionIssues }
    } = this.props;

    let nextStep;
    const dispositions = decisionIssues.map((issue) => issue.disposition);
    const remandedIssues = _.some(dispositions, (disp) => [
      VACOLS_DISPOSITIONS.REMANDED, ISSUE_DISPOSITIONS.REMANDED
    ].includes(disp));

    if (remandedIssues) {
      nextStep = 'remands';
    } else if (userRole === USER_ROLE_TYPES.judge) {
      nextStep = 'evaluate';
    } else {
      nextStep = 'submit';
    }

    return `/queue/appeals/${appealId}/tasks/${taskId}/${checkoutFlow}/${nextStep}`;
  }

  getPrevStepUrl = () => {
    const {
      appealId,
      appeal,
      taskId,
      checkoutFlow
    } = this.props;

    if (appeal.isLegacyAppeal) {
      return `/queue/appeals/${appealId}/tasks/${taskId}/${checkoutFlow}/special_issues`;
    }

    return `/queue/appeals/${appealId}`;

  }

  validateForm = () => {
    const { appeal: { issues, decisionIssues } } = this.props;

    return issues.every((issue) => {
      return decisionIssues.some((decisionIssue) => decisionIssue.request_issue_ids.includes(issue.id));
    });
  }
  openDeleteAddedDecisionIssueHandler = (requestIdToDelete, decisionIssue) => {
    this.setState({
      deleteAddedDecisionIssue: true,
      requestIdToDelete,
      decisionIssue
    });
  }

  openDecisionHandler = (requestIssueId, decisionIssue) => () => {
    const benefitType = _.find(this.props.appeal.issues, (issue) => requestIssueId === issue.id).program;
    const diagnosticCode = _.find(this.props.appeal.issues, (issue) => requestIssueId === issue.id).diagnostic_code;

    const newDecisionIssue = {
      id: `temporary-id-${uuid.v4()}`,
      description: '',
      disposition: null,
      benefit_type: benefitType,
      diagnostic_code: diagnosticCode,
      request_issue_ids: [requestIssueId]
    };

    this.setState({
      openRequestIssueId: requestIssueId,
      decisionIssue: decisionIssue || newDecisionIssue,
      editingExistingIssue: Boolean(decisionIssue),
      deleteAddedDecisionIssue: null
    });
  }

  handleModalClose = () => {
    this.setState({
      openRequestIssueId: null,
      decisionIssue: null,
      editingExistingIssue: false,
      highlightModal: false,
      deleteAddedDecisionIssue: null,
      requestIdToDelete: null
    });
  }

  validate = () => {
    const { decisionIssue } = this.state;

    return decisionIssue.benefit_type && decisionIssue.disposition &&
      decisionIssue.description;
  }

  saveDecision = () => {
    if (!this.validate()) {
      this.setState({
        highlightModal: true
      });

      return;
    }

    let newDecisionIssues;

    if (this.state.editingExistingIssue) {
      newDecisionIssues = this.props.appeal.decisionIssues.map((decisionIssue) => {
        if (decisionIssue.id === this.state.decisionIssue.id) {
          return this.state.decisionIssue;
        }

        return decisionIssue;
      });
    } else {
      newDecisionIssues = [...this.props.appeal.decisionIssues, this.state.decisionIssue];
    }

    this.props.editStagedAppeal(
      this.props.appeal.externalId, { decisionIssues: newDecisionIssues }
    );

    this.handleModalClose();
  }

  deleteDecision = () => {
    const remainingDecisionIssues = this.props.appeal.decisionIssues.filter((decisionIssue) => {
      return decisionIssue.id !== this.state.decisionIssue.id;
    });

    this.props.editStagedAppeal(
      this.props.appeal.externalId, { decisionIssues: remainingDecisionIssues }
    );

    this.handleModalClose();
  }

  selectedIssues = () => {
    if (!this.state.openRequestIssueId) {
      return [];
    }

    return this.props.appeal.issues.filter((issue) => {
      return this.state.openRequestIssueId === issue.id;
    });
  }

  decisionModalButtons = [
    { classNames: ['cf-modal-link', 'cf-btn-link'],
      name: 'Close',
      onClick: this.handleModalClose
    },
    { classNames: ['usa-button', 'usa-button-primary'],
      name: 'Save',
      onClick: this.saveDecision
    }
  ];

  deleteAddedDecisionIssueModalButtons = [
    { classNames: ['cf-modal-link', 'cf-btn-link'],
      name: 'Cancel',
      onClick: this.handleModalClose
    },
    { classNames: ['usa-button', 'usa-button-primary'],
      name: 'Yes, delete decision',
      onClick: this.deleteDecision
    }
  ];

  connectedRequestIssuesWithoutCurrentId = (idsArray, idToFilter) => {
    return idsArray.filter((issue) => {
      return issue.id !== idToFilter;
    });
  }

  render = () => {
    const { appeal, highlight, ...otherProps } = this.props;

    const {
      highlightModal,
      decisionIssue,
      openRequestIssueId,
      editingExistingIssue,
      deleteAddedDecisionIssue,
      requestIdToDelete
    } = this.state;

    const connectedRequestIssues = appeal.issues.filter((issue) => {
      return decisionIssue && decisionIssue.request_issue_ids.includes(issue.id);
    });
    const connectedIssues = this.connectedRequestIssuesWithoutCurrentId(connectedRequestIssues, requestIdToDelete);
    const toDeleteHasConnectedIssue = connectedIssues.length > 0;

    const decisionIssues = (
      <DecisionIssues
        decisionIssues={appeal.decisionIssues}
        openDecisionHandler={this.openDecisionHandler}
        openDeleteAddedDecisionIssueHandler={this.openDeleteAddedDecisionIssueHandler} />
    );

    const hasDecisionIssue = appeal.decisionIssues.some(
      (decisionIssue) => decisionIssue.request_issue_ids.includes(issue.id)
    );
    const decisionIssueErrorMessage = highlight && !hasDecisionIssue &&
      'You must add a decision before you continue.';

    return <QueueFlowPage
      validateForm={this.validateForm}
      getNextStepUrl={this.getNextStepUrl}
      getPrevStepUrl={this.getPrevStepUrl}
      {...otherProps}
    >
      <h1>{COPY.DECISION_ISSUE_PAGE_TITLE}</h1>
      <p>{COPY.DECISION_ISSUE_PAGE_EXPLANATION}</p>
      <hr />
      <IssueAma
        requestIssues={appeal.issues}
        errorMessage={decisionIssueErrorMessage}
        children={decisionIssues} />
      { deleteAddedDecisionIssue && <Modal
        buttons = {this.deleteAddedDecisionIssueModalButtons}
        closeHandler={this.handleModalClose}
        title = "Delete decision">
        <span className="delete-decision-modal">
          {COPY.DECISION_ISSUE_CONFIRM_DELETE}
          {toDeleteHasConnectedIssue && COPY.DECISION_ISSUE_CONFIRM_DELETE_WITH_CONNECTED_ISSUES}
        </span>
      </Modal>}
      { openRequestIssueId && <Modal
        buttons = {this.decisionModalButtons}
        closeHandler={this.handleModalClose}
        title = {`${editingExistingIssue ? 'Edit' : 'Add'} decision`}
        customStyles={css({
          width: '800px'
        })}
      >

        <div {...contestedIssueStyling}>
          {COPY.CONTESTED_ISSUE}
          <ul>
            {
              connectedRequestIssues.map((issue) => <li key={issue.id}>{issue.description}</li>)
            }
          </ul>
        </div>

        {!editingExistingIssue &&
          <React.Fragment>
            <h3>{COPY.DECISION_ISSUE_MODAL_TITLE}</h3>
            <p {...paragraphH3SiblingStyle}>{COPY.DECISION_ISSUE_MODAL_SUB_TITLE}</p>
          </React.Fragment>
        }

        <h3>{COPY.DECISION_ISSUE_MODAL_DISPOSITION}</h3>
        <SelectIssueDispositionDropdown
          highlight={highlightModal}
          issue={decisionIssue}
          appeal={appeal}
          updateIssue={({ disposition }) => {
            this.setState({
              decisionIssue: {
                ...decisionIssue,
                disposition
              }
            });
          }}
          noStyling
        />
        <br />
        <h3>{COPY.DECISION_ISSUE_MODAL_DESCRIPTION}</h3>
        <TextareaField
          labelStyling={textAreaStyle}
          styling={textAreaStyle}
          errorMessage={highlightModal && !decisionIssue.description ? 'This field is required' : null}
          label={COPY.DECISION_ISSUE_MODAL_DESCRIPTION_EXAMPLE}
          name="Text Box"
          onChange={(issueDescription) => {
            this.setState({
              decisionIssue: {
                ...decisionIssue,
                description: issueDescription
              }
            });
          }}
          value={decisionIssue.description}
        />
        <h3>{COPY.DECISION_ISSUE_MODAL_DIAGNOSTIC_CODE}</h3>
        <SearchableDropdown
          name="Diagnostic code"
          placeholder={COPY.DECISION_ISSUE_MODAL_DIAGNOSTIC_CODE}
          hideLabel
          value={decisionIssue.diagnostic_code}
          options={_.map(Object.keys(DIAGNOSTIC_CODE_DESCRIPTIONS), (key) => ({ label: key,
            value: key }))}
          onChange={(diagnosticCode) => this.setState({
            decisionIssue: {
              ...decisionIssue,
              diagnostic_code: diagnosticCode ? diagnosticCode.value : ''
            }
          })}
        />
        <h3>{COPY.DECISION_ISSUE_MODAL_BENEFIT_TYPE}</h3>
        <SearchableDropdown
          name="Benefit type"
          placeholder={COPY.DECISION_ISSUE_MODAL_BENEFIT_TYPE}
          hideLabel
          value={decisionIssue.benefit_type}
          options={_.map(BENEFIT_TYPES, (value, key) => ({ label: value,
            value: key }))}
          onChange={(benefitType) => this.setState({
            decisionIssue: {
              ...decisionIssue,
              benefit_type: benefitType.value
            }
          })}
        />
        <h3>{COPY.DECISION_ISSUE_MODAL_CONNECTED_ISSUES_DESCRIPTION}</h3>
        <p {...exampleDiv} {...paragraphH3SiblingStyle}>{COPY.DECISION_ISSUE_MODAL_CONNECTED_ISSUES_EXAMPLE}</p>
        <h3>{COPY.DECISION_ISSUE_MODAL_CONNECTED_ISSUES_TITLE}</h3>
        <SearchableDropdown
          name="Issues"
          placeholder="Select issues"
          hideLabel
          value={null}
          options={appeal.issues.
            filter((issue) => !decisionIssue.request_issue_ids.includes(issue.id)).
            map((issue) => (
              {
                label: issue.description,
                value: issue.id
              }
            ))
          }
          onChange={(issue) => this.setState({
            decisionIssue: {
              ...decisionIssue,
              request_issue_ids: [...decisionIssue.request_issue_ids, issue.value]
            }
          })}
        />
        {
          this.connectedRequestIssuesWithoutCurrentId(connectedRequestIssues, openRequestIssueId).
            map((issue) =>
              <div key={issue.id} {...connectedIssueDiv}>
                <span>{issue.description}</span>
                <Button
                  classNames={['cf-btn-link']}
                  onClick={() => this.setState({
                    decisionIssue: {
                      ...decisionIssue,
                      request_issue_ids: decisionIssue.request_issue_ids.filter((id) => id !== issue.id)
                    }
                  })}
                >
                Remove
                </Button>
              </div>
            )
        }
      </Modal>}
    </QueueFlowPage>;
  };
}

SelectDispositionsView.propTypes = {
  appealId: PropTypes.string.isRequired,
  checkoutFlow: PropTypes.string.isRequired,
  userRole: PropTypes.string.isRequired
};

const mapStateToProps = (state, ownProps) => ({
  appeal: state.queue.stagedChanges.appeals[ownProps.appealId],
  success: state.ui.messages.success,
  highlight: state.ui.highlightFormItems,
  ..._.pick(state.ui, 'userRole')
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  setDecisionOptions,
  hideSuccessMessage,
  editStagedAppeal
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(SelectDispositionsView);
