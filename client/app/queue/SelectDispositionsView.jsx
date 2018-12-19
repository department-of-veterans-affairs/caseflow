import React from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import _ from 'lodash';
import { css } from 'glamor';

import Button from '../components/Button';
import decisionViewBase from './components/DecisionViewBase';
import SelectIssueDispositionDropdown from './components/SelectIssueDispositionDropdown';
import Modal from '../components/Modal';
import TextareaField from '../components/TextareaField';
import SearchableDropdown from '../components/SearchableDropdown';
import ContestedIssues, { contestedIssueStyling } from './components/ContestedIssues';
import COPY from '../../COPY.json';

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
import uuid from 'uuid';

const connectedIssueDiv = css({
  display: 'flex',
  justifyContent: 'space-between',
  marginBottom: '10px'
});

class SelectDispositionsView extends React.PureComponent {
  constructor(props) {
    super(props);

    this.state = {
      openRequestIssueId: null,
      decisionIssue: null,
      editingExistingIssue: false,
      highlightModal: false
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
      taskId,
      checkoutFlow
    } = this.props;

    return `/queue/appeals/${appealId}/tasks/${taskId}/${checkoutFlow}/special_issues`;
  }

  validateForm = () => {
    const { appeal: { issues, decisionIssues } } = this.props;

    return issues.every((issue) => {
      return decisionIssues.some((decisionIssue) => decisionIssue.request_issue_ids.includes(issue.id));
    });
  }

  openDecisionHandler = (requestIssueId, decisionIssue) => () => {
    const benefitType = _.find(this.props.appeal.issues, (issue) => requestIssueId === issue.id).program;

    const newDecisionIssue = {
      id: `temporary-id-${uuid.v4()}`,
      description: '',
      disposition: null,
      benefit_type: benefitType,
      request_issue_ids: [requestIssueId]
    };

    this.setState({
      openRequestIssueId: requestIssueId,
      decisionIssue: decisionIssue || newDecisionIssue,
      editingExistingIssue: Boolean(decisionIssue)
    });
  }

  handleModalClose = () => {
    this.setState({
      openRequestIssueId: null,
      decisionIssue: null,
      editingExistingIssue: false,
      highlightModal: false
    });
  }

  validate = () => {
    const { decisionIssue } = this.state;

    return decisionIssue.benefit_type && decisionIssue.disposition && decisionIssue.description;
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

  render = () => {
    const { appeal, highlight } = this.props;
    const {
      highlightModal,
      decisionIssue,
      openRequestIssueId,
      editingExistingIssue
    } = this.state;

    const modalButtons = [
      { classNames: ['cf-modal-link', 'cf-btn-link'],
        name: 'Close',
        onClick: this.handleModalClose
      },
      { classNames: ['usa-button', 'usa-button-primary'],
        name: 'Save',
        onClick: this.saveDecision
      }
    ];

    if (editingExistingIssue) {
      modalButtons.push({ classNames: ['usa-button', 'usa-button-secondary'],
        name: 'Delete decision',
        onClick: this.deleteDecision
      });
    }

    const connectedRequestIssues = appeal.issues.filter((issue) => {
      return decisionIssue && decisionIssue.request_issue_ids.includes(issue.id);
    });

    return <React.Fragment>
      <h1>{COPY.DECISION_ISSUE_PAGE_TITLE}</h1>
      <p>{COPY.DECISION_ISSUE_PAGE_EXPLANATION}</p>
      <hr />

      <ContestedIssues
        decisionIssues={appeal.decisionIssues}
        requestIssues={appeal.issues}
        openDecisionHandler={this.openDecisionHandler}
        numbered
        highlight={highlight}
      />
      { openRequestIssueId && <Modal
        buttons = {modalButtons}
        closeHandler={this.handleModalClose}
        title = {`${editingExistingIssue ? 'Edit' : 'Add'} decision`}>

        <div {...contestedIssueStyling}>
          Contested Issue
          <ul>
            {
              connectedRequestIssues.map((issue) => <li key={issue.id}>{issue.description}</li>)
            }
          </ul>
        </div>

        {!editingExistingIssue &&
          <React.Fragment>
            <h3>{COPY.DECISION_ISSUE_MODAL_TITLE}</h3>
            <p>{COPY.DECISION_ISSUE_MODAL_SUB_TITLE}</p>
          </React.Fragment>
        }

        <h3>{COPY.DECISION_ISSUE_MODAL_DESCRIPTION}</h3>
        <TextareaField
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
        <p>{COPY.DECISION_ISSUE_MODAL_CONNECTED_ISSUES_DESCRIPTION}</p>
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
          connectedRequestIssues.filter((issue) => {
            return issue.id !== openRequestIssueId
          }).map((issue) =>
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
    </React.Fragment>;
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

export default connect(mapStateToProps, mapDispatchToProps)(decisionViewBase(SelectDispositionsView));
