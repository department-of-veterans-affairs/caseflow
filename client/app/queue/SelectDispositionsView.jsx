/* eslint-disable max-lines, camelcase, max-len */
import React from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import _ from 'lodash';
import { css } from 'glamor';

import Button from '../components/Button';
import AmaIssueList from '../components/AmaIssueList';
import DecisionIssues from './components/DecisionIssues';
import SelectIssueDispositionDropdown from './components/SelectIssueDispositionDropdown';
import Modal from '../components/Modal';
import TextareaField from '../components/TextareaField';
import SearchableDropdown from '../components/SearchableDropdown';
import QueueCheckboxGroup from './components/QueueCheckboxGroup';
import COPY from '../../COPY';
import { COLORS } from '../constants/AppConstants';

import {
  setDecisionOptions,
  editStagedAppeal
} from './QueueActions';
import { hideSuccessMessage } from './uiReducer/uiActions';
import {
  VACOLS_DISPOSITIONS,
  ISSUE_DISPOSITIONS,
  DECISION_SPECIAL_ISSUES,
  DECISION_SPECIAL_ISSUES_NO_MST_PACT
} from './constants';
import ApiUtil from '../util/ApiUtil';

import BENEFIT_TYPES from '../../constants/BENEFIT_TYPES';
import DIAGNOSTIC_CODE_DESCRIPTIONS from '../../constants/DIAGNOSTIC_CODE_DESCRIPTIONS';
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

const specialIssuesCheckboxStyling = css({
  columnCount: '1',
  marginTop: '2%',
  maxWidth: '70%',
  '& legend': {
    marginBottom: '2%',
  },
  '& .checkbox': {
    marginTop: '0',
  },
});

class SelectDispositionsView extends React.PureComponent {
  constructor(props) {
    super(props);

    this.state = {
      openRequestIssueId: null,
      decisionIssue: null,
      editingExistingIssue: false,
      highlightModal: false,
      deleteAddedDecisionIssue: null,
      specialIssues: null,
      mstJustification: '',
      pactJustification: ''
    };
  }
  decisionReviewCheckoutFlow = () => this.props.checkoutFlow === 'dispatch_decision';

  componentDidMount = () => {
    if (!this.decisionReviewCheckoutFlow()) {
      this.props.setDecisionOptions({ work_product: 'Decision' });
    }
    ApiUtil.get(
      `/appeals/${this.props.appealId}/special_issues`).then(
      (response) => {
        const { ...specialIssues } = response.body;

        this.editStagedAppeal({ specialIssues });
        this.setState({ specialIssues });
      }
    );
  }

  stageSpecialIssues = (decisionIssues) => {
    const appealIsBlueWater = decisionIssues.filter(
      // eslint-disable-next-line camelcase, no-unneeded-ternary
      (decision) => decision.decisionSpecialIssue?.blue_water).length > 0;

    const appealIsBurnPit = decisionIssues.filter(
      // eslint-disable-next-line camelcase, no-unneeded-ternary
      (decision) => decision.decisionSpecialIssue?.burn_pit).length > 0;

    this.setState({ specialIssues: {
      ...this.state.specialIssues,
      blue_water: appealIsBlueWater,
      burn_pit: appealIsBurnPit
    } });

    this.props.editStagedAppeal(
      this.props.appeal.externalId, {
        specialIssues: {
          ...this.state.specialIssues,
          blue_water: appealIsBlueWater,
          burn_pit: appealIsBurnPit
        }
      }
    );
  }

  createSpecialIssueList = (decisionIssues) => {
    const blueWater = decisionIssues.filter(
      // eslint-disable-next-line camelcase, no-unneeded-ternary
      (decision) => decision.decisionSpecialIssue?.blue_water);

    const burnPit = decisionIssues.filter(
      // eslint-disable-next-line camelcase, no-unneeded-ternary
      (decision) => decision.decisionSpecialIssue?.burn_pit);

    return {
      ...this.state.specialIssues,
      blue_water: _.some(blueWater, (bW) => bW.decisionSpecialIssue.blue_water === true),
      burn_pit: _.some(burnPit, (bP) => bP.decisionSpecialIssue.burn_pit === true)
    };
  };

  getNextStepUrl = () => {
    const {
      appealId,
      taskId,
      checkoutFlow,
      appeal: { decisionIssues }
    } = this.props;

    ApiUtil.post(`/appeals/${appealId}/special_issues`,
      {
        data: { special_issues: this.createSpecialIssueList(decisionIssues) }
      });

    let nextStep;
    const dispositions = decisionIssues.map((issue) => issue.disposition);
    const remandedIssues = _.some(dispositions, (disp) => [
      VACOLS_DISPOSITIONS.REMANDED, ISSUE_DISPOSITIONS.REMANDED
    ].includes(disp));

    if (remandedIssues) {
      nextStep = 'remands';
    } else if (this.decisionReviewCheckoutFlow()) {
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
      checkoutFlow,
      mstFeatureToggle,
      pactFeatureToggle
    } = this.props;

    // route to case details instead of special issues for MST/PACT
    return (mstFeatureToggle || pactFeatureToggle) ? `/queue/appeals/${appealId}` :
      `/queue/appeals/${appealId}/tasks/${taskId}/${checkoutFlow}/special_issues`;
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
    const closedStatus = _.find(this.props.appeal.issues, (issue) => requestIssueId === issue.id).closed_status;
    const mst_justification = _.find(this.props.appeal.issues, (issue) => requestIssueId === issue.id).mst_justification;
    const pact_justification = _.find(this.props.appeal.issues, (issue) => requestIssueId === issue.id).pact_justification;
    const mst_status = _.find(this.props.appeal.issues, (issue) => requestIssueId === issue.id).mst_status;
    const pact_status = _.find(this.props.appeal.issues, (issue) => requestIssueId === issue.id).pact_status;

    const newDecisionIssue = {
      id: `temporary-id-${uuid.v4()}`,
      description: '',
      disposition: closedStatus,
      benefit_type: benefitType,
      diagnostic_code: diagnosticCode,
      request_issue_ids: [requestIssueId],
      mst_justification,
      pact_justification,
      mst_status,
      mstOriginalStatus: mst_status,
      pact_status,
      pactOriginalStatus: pact_status,

      /*
        Burn Pit and Blue Water will still be tracked on the appeal level but,
        SelectSpecialIssuesView.jsx is no longer utilized for AMA appeals.
        So we must temporarily track it on the issue level. As long as one
        decision has the issue checked, it will be applied to whole appeal.
      */
      decisionSpecialIssue: null,
    };

    this.setState({
      openRequestIssueId: requestIssueId,
      decisionIssue: decisionIssue || newDecisionIssue,
      editingExistingIssue: Boolean(decisionIssue),
      deleteAddedDecisionIssue: null,
      mstJustification: mst_justification,
      pactJustification: pact_justification,
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

  validBenefitType = (benefitType) => Object.keys(BENEFIT_TYPES).includes(benefitType);

  validate = () => {
    const { decisionIssue } = this.state;

    return this.validBenefitType(decisionIssue.benefit_type) && decisionIssue.disposition && decisionIssue.description;
  }

  validateJustification = (justificationFeatureToggle) => {
    const { decisionIssue } = this.state;
    const mstHasChanged = decisionIssue.mstOriginalStatus !== decisionIssue.mst_status;
    const pactHasChanged = decisionIssue.pactOriginalStatus !== decisionIssue.pact_status;

    if (mstHasChanged && (decisionIssue.mst_justification === '' || decisionIssue.mst_justification === null) &&
      justificationFeatureToggle) {
      return false;
    }
    if (pactHasChanged && (decisionIssue.pact_justification === '' || decisionIssue.pact_justification === null) &&
      justificationFeatureToggle) {
      return false;
    }

    return true;
  }

  saveDecision = () => {
    if (!this.validate()) {
      this.setState({
        highlightModal: true
      });

      return;
    }

    if (!this.validateJustification()) {
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

    this.stageSpecialIssues(this.props.appeal.decisionIssues);
    this.handleModalClose();
  }

  deleteDecision = () => {
    const remainingDecisionIssues = this.props.appeal.decisionIssues.filter((decisionIssue) => {
      return decisionIssue.id !== this.state.decisionIssue.id;
    });

    this.props.editStagedAppeal(
      this.props.appeal.externalId, { decisionIssues: remainingDecisionIssues }
    );

    // Reverts special issues view to their original status when deleting decision
    this.selectedIssuesToDelete()[0].mst_status = this.state.decisionIssue.mstOriginalStatus;
    this.selectedIssuesToDelete()[0].pact_status = this.state.decisionIssue.pactOriginalStatus;

    this.handleModalClose();
  }

  selectedIssuesToDelete = () => {
    if (!this.state.requestIdToDelete) {
      return [];
    }

    return this.props.appeal.issues.filter((issue) => {
      return this.state.requestIdToDelete === issue.id;
    });
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

  onJustificationChange = (event, decision, type) => {

    if (type === 'mst_status') {
      this.setState({
        decisionIssue: {
          ...decision,
          mst_justification: event
        }
      });
      this.setState({ mstJustification: event });
    } else if (type === 'pact_status') {
      this.setState({
        decisionIssue: {
          ...decision,
          pact_justification: event
        }
      });
      this.setState({ pactJustification: event });
    }
  }

  filterIssuesForJustification = (issues, idToFilter) => {
    return issues.filter((issue) => {
      return issue.id === idToFilter;
    });
  }

  onCheckboxChange = (event, decision) => {
    const checkboxId = event.target.getAttribute('id');

    if (checkboxId === 'mst_status' || checkboxId === 'pact_status') {
      this.setState({
        decisionIssue: {
          ...decision,
          [checkboxId]: event.target.checked,
        }
      });
    }
    if (checkboxId === 'blue_water' || checkboxId === 'burn_pit') {
      this.setState({
        decisionIssue: {
          ...decision,
          decisionSpecialIssue: {
            ...decision.decisionSpecialIssue,
            [checkboxId]: event.target.checked,
          }
        }
      });
    }
  };

  render = () => {
    const {
      appeal,
      highlight,
      justificationFeatureToggle,
      mstFeatureToggle,
      pactFeatureToggle,
      ...otherProps
    } = this.props;
    const {
      highlightModal,
      decisionIssue,
      openRequestIssueId,
      editingExistingIssue,
      deleteAddedDecisionIssue,
      requestIdToDelete,
    } = this.state;
    const connectedRequestIssues = appeal.issues.filter((issue) => {
      return decisionIssue && decisionIssue.request_issue_ids.includes(issue.id);
    });
    const connectedIssues = this.connectedRequestIssuesWithoutCurrentId(connectedRequestIssues, requestIdToDelete);
    const toDeleteHasConnectedIssue = connectedIssues.length > 0;

    const specialIssuesValues = {
      // eslint-disable-next-line camelcase
      blue_water: decisionIssue?.decisionSpecialIssue?.blue_water,
      // eslint-disable-next-line camelcase
      burn_pit: decisionIssue?.decisionSpecialIssue?.burn_pit,
      mst_status: decisionIssue?.mst_status,
      pact_status: decisionIssue?.pact_status
    };

    // In order to determine whether or not to display error styling and an error message for each issue,
    // determine if highlight is set to true and if there is not a decision issue
    const issueErrors = {};

    appeal.issues.forEach((issue) => {
      const hasDecisionIssue = appeal.decisionIssues.some(
        (decisionIssueAma) => decisionIssueAma.request_issue_ids.includes(issue.id)
      );

      issueErrors[issue.id] = highlight && !hasDecisionIssue &&
        'You must add a decision before you continue.';
    });

    return <QueueFlowPage
      validateForm={this.validateForm}
      getNextStepUrl={this.getNextStepUrl}
      getPrevStepUrl={this.getPrevStepUrl}
      {...otherProps}
    >
      <h1>{COPY.DECISION_ISSUE_PAGE_TITLE}</h1>
      <p>{COPY.DECISION_ISSUE_PAGE_EXPLANATION}</p>
      <hr />
      <AmaIssueList
        requestIssues={appeal.issues}
        mstFeatureToggle={mstFeatureToggle}
        pactFeatureToggle={pactFeatureToggle}
        errorMessages={issueErrors}>
        <DecisionIssues
          mstFeatureToggle={mstFeatureToggle}
          pactFeatureToggle={pactFeatureToggle}
          decisionIssues={appeal.decisionIssues}
          openDecisionHandler={this.openDecisionHandler}
          openDeleteAddedDecisionIssueHandler={this.openDeleteAddedDecisionIssueHandler} />
      </AmaIssueList>
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
        customStyles={css({ width: '800px' })}>
        <div>
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
          errorMessage={highlightModal && !decisionIssue.description ? 'Text box field is required' : null}
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
          errorMessage={highlightModal && !this.validBenefitType(decisionIssue.benefit_type) ?
            'Benefit type field is required' : null}
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
        { (mstFeatureToggle || pactFeatureToggle) && <QueueCheckboxGroup
          name={COPY.INTAKE_EDIT_ISSUE_SELECT_SPECIAL_ISSUES}
          options={(mstFeatureToggle || pactFeatureToggle) ? DECISION_SPECIAL_ISSUES : DECISION_SPECIAL_ISSUES_NO_MST_PACT}
          values={specialIssuesValues}
          styling={specialIssuesCheckboxStyling}
          onChange={(event) => this.onCheckboxChange(event, decisionIssue)}
          errorState={{
            highlightModal,
            invalid: !this.validateJustification(justificationFeatureToggle),
          }
          }
          filterIssuesForJustification={this.filterIssuesForJustification}
          justificationFeatureToggle={justificationFeatureToggle}
          mstFeatureToggle={mstFeatureToggle}
          pactFeatureToggle={pactFeatureToggle}
          justifications={[
            {
              id: 'mst_status',
              justification: decisionIssue.mst_justification,
              onJustificationChange: (event) => this.onJustificationChange(event, decisionIssue, 'mst_status'),
              hasChanged: this.state.decisionIssue.mstOriginalStatus !== this.state.decisionIssue.mst_status
            },
            {
              id: 'pact_status',
              justification: decisionIssue.pact_justification,
              onJustificationChange: (event) => this.onJustificationChange(event, decisionIssue, 'pact_status'),
              hasChanged: this.state.decisionIssue.pactOriginalStatus !== this.state.decisionIssue.pact_status
            },
          ]}
        />}
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
  appeal: PropTypes.shape({
    decisionIssues: PropTypes.array,
    specialIssues: PropTypes.object,
    externalId: PropTypes.string,
    isLegacyAppeal: PropTypes.bool,
    issues: PropTypes.array
  }),
  appealId: PropTypes.string.isRequired,
  checkoutFlow: PropTypes.string.isRequired,
  editStagedAppeal: PropTypes.func,
  hideSuccessMessage: PropTypes.func,
  highlight: PropTypes.bool,
  setDecisionOptions: PropTypes.func,
  taskId: PropTypes.string,
  justificationFeatureToggle: PropTypes.bool,
  mstFeatureToggle: PropTypes.bool,
  pactFeatureToggle: PropTypes.bool
};

const mapStateToProps = (state, ownProps) => ({
  appeal: state.queue.stagedChanges.appeals[ownProps.appealId],
  success: state.ui.messages.success,
  highlight: state.ui.highlightFormItems,
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  setDecisionOptions,
  hideSuccessMessage,
  editStagedAppeal
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(SelectDispositionsView);

