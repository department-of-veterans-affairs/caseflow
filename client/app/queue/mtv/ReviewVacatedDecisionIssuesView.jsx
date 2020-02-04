import React from 'react';
import PropTypes from 'prop-types';

import COPY from '../../../COPY.json';
import QueueFlowPage from '../components/QueueFlowPage';
import AmaIssueList from '../../components/AmaIssueList';
import DecisionIssues from '../components/DecisionIssues';

const validateForm = () => true;

export const ReviewVacatedDecisionIssuesView = ({ appeal }) => {
  const issueErrors = {};

  return (
    <QueueFlowPage
      validateForm={validateForm}
      //   getNextStepUrl={this.getNextStepUrl}
      //   getPrevStepUrl={this.getPrevStepUrl}
    >
      <h1>{COPY.DECISION_ISSUE_PAGE_TITLE}</h1>
      <p>{COPY.DECISION_ISSUE_PAGE_EXPLANATION}</p>
      <hr />
      <AmaIssueList requestIssues={appeal.issues} errorMessages={issueErrors}>
        <DecisionIssues
          decisionIssues={appeal.decisionIssues}
          openDecisionHandler={this.openDecisionHandler}
          openDeleteAddedDecisionIssueHandler={this.openDeleteAddedDecisionIssueHandler}
        />
      </AmaIssueList>
      {/* {deleteAddedDecisionIssue && (
        <Modal
          buttons={this.deleteAddedDecisionIssueModalButtons}
          closeHandler={this.handleModalClose}
          title="Delete decision"
        >
          <span className="delete-decision-modal">
            {COPY.DECISION_ISSUE_CONFIRM_DELETE}
            {toDeleteHasConnectedIssue && COPY.DECISION_ISSUE_CONFIRM_DELETE_WITH_CONNECTED_ISSUES}
          </span>
        </Modal>
      )}
      {openRequestIssueId && (
        <Modal
          buttons={this.decisionModalButtons}
          closeHandler={this.handleModalClose}
          title={`${editingExistingIssue ? 'Edit' : 'Add'} decision`}
          customStyles={css({ width: '800px' })}
        >
          <div>
            {COPY.CONTESTED_ISSUE}
            <ul>
              {connectedRequestIssues.map((issue) => (
                <li key={issue.id}>{issue.description}</li>
              ))}
            </ul>
          </div>

          {!editingExistingIssue && (
            <React.Fragment>
              <h3>{COPY.DECISION_ISSUE_MODAL_TITLE}</h3>
              <p {...paragraphH3SiblingStyle}>{COPY.DECISION_ISSUE_MODAL_SUB_TITLE}</p>
            </React.Fragment>
          )}

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
            onChange={(diagnosticCode) =>
              this.setState({
                decisionIssue: {
                  ...decisionIssue,
                  diagnostic_code: diagnosticCode ? diagnosticCode.value : ''
                }
              })
            }
          />
          <h3>{COPY.DECISION_ISSUE_MODAL_BENEFIT_TYPE}</h3>
          <SearchableDropdown
            name="Benefit type"
            placeholder={COPY.DECISION_ISSUE_MODAL_BENEFIT_TYPE}
            hideLabel
            value={decisionIssue.benefit_type}
            options={_.map(BENEFIT_TYPES, (value, key) => ({ label: value,
              value: key }))}
            onChange={(benefitType) =>
              this.setState({
                decisionIssue: {
                  ...decisionIssue,
                  benefit_type: benefitType.value
                }
              })
            }
          />
          <h3>{COPY.DECISION_ISSUE_MODAL_CONNECTED_ISSUES_DESCRIPTION}</h3>
          <p {...exampleDiv} {...paragraphH3SiblingStyle}>
            {COPY.DECISION_ISSUE_MODAL_CONNECTED_ISSUES_EXAMPLE}
          </p>
          <h3>{COPY.DECISION_ISSUE_MODAL_CONNECTED_ISSUES_TITLE}</h3>
          <SearchableDropdown
            name="Issues"
            placeholder="Select issues"
            hideLabel
            value={null}
            options={appeal.issues.
              filter((issue) => !decisionIssue.request_issue_ids.includes(issue.id)).
              map((issue) => ({
                label: issue.description,
                value: issue.id
              }))}
            onChange={(issue) =>
              this.setState({
                decisionIssue: {
                  ...decisionIssue,
                  request_issue_ids: [...decisionIssue.request_issue_ids, issue.value]
                }
              })
            }
          />
          {this.connectedRequestIssuesWithoutCurrentId(connectedRequestIssues, openRequestIssueId).map((issue) => (
            <div key={issue.id} {...connectedIssueDiv}>
              <span>{issue.description}</span>
              <Button
                classNames={['cf-btn-link']}
                onClick={() =>
                  this.setState({
                    decisionIssue: {
                      ...decisionIssue,
                      request_issue_ids: decisionIssue.request_issue_ids.filter((id) => id !== issue.id)
                    }
                  })
                }
              >
                Remove
              </Button>
            </div>
          ))}
        </Modal>
      )} */}
    </QueueFlowPage>
  );
};

ReviewVacatedDecisionIssuesView.propTypes = {
  appeal: PropTypes.object.isRequired
};
