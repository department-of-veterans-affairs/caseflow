import React, { PropTypes } from 'react';
import DropDown from '../../components/DropDown';
import Checkbox from '../../components/Checkbox';
import Modal from '../../components/Modal';
import Button from '../../components/Button';
import { formatDate, addDays } from '../../util/DateUtil';
import ApiUtil from '../../util/ApiUtil';
import Table from '../../components/Table';
import TabWindow from '../../components/TabWindow';

const TABLE_HEADERS = ['Program', 'VACOLS Issue(s)', 'Disposition'];

export const DECISION_TYPE = [
  'Full Grant',
  'Partial Grant',
  'Remand'
];

export const SPECIAL_ISSUE_FULL = [
  'Rice Compliance',
  'Private Attorney',
  'Waiver of Overpayment',
  'Pensions',
  'VAMC',
  'Incarcerated Veterans',
  'DIC - death, or accrued benefits',
  'Education or Vocational Rehab',
  'Foreign Claims'
];

export const SPECIAL_ISSUE_PARTIAL = [
  'Manlincon Compliance',
  'Rice Compliance',
  'Private Attorney',
  'Hearings - travel board & video conference',
  'Contaminated Water at Camp Lejeune',
  'Home Loan Guaranty',
  'Waiver of Overpayment',
  'Education or Vocational Rehab',
  'VAMC',
  'Insurance',
  'National Cemetery Administration',
  'Spina Bifida',
  'Radiation',
  'Non-rating Issues',
  'Foreign Claims',
  'Incarcerated Veterans',
  'Proposed Incompetency',
  'Manila Remand',
  'Mustard Gas',
  'Dependencies',
  'DIC - death, or accrued benefits'
];

export const UNHANDLED_SPECIAL_ISSUES = [
  'Pensions',
  'VAMC',
  'DIC - death, or accrued benefits',
  'Foreign Claims',
  'Education or Vocational Rehab',
  'Waiver of Overpayment',
  'National Cemetery Administration'
];

export const ROUTING_SPECIAL_ISSUES = [
  {
    specialIssue: 'mustardGas',
    stationOfJurisdiction: '351 - Muskogee, OK'
  },
  {
    specialIssue: 'contaminatedWaterAtCampLejeune',
    stationOfJurisdiction: '327 - Louisville, KY'
  }
];

export const REGIONAL_OFFICE_SPECIAL_ISSUES = [
  'dependencies',
  'educationOrVocationalRehab',
  'hearingsTravelBoardVideoConference',
  'homeLoanGuaranty',
  'incarceratedVeterans',
  'manilaRemand',
  'manlinconCompliance',
  'nonratingIssues',
  'privateAttorney',
  'proposedIncompetency',
  'radiation',
  'riceCompliance',
  'spinaBifida'
];

export default class EstablishClaimReview extends React.Component {
  constructor(props) {
    super(props);
    let endProductButtonText;

    if (this.hasMultipleDecisions()) {
      endProductButtonText = "Create End Product For Decision 1";
    } else {
      endProductButtonText = "Create End Product";
    }
    this.state = {
      endProductButtonText
    };
  }

  onTabSelected = (tabNumber) => {
    this.setState({
      endProductButtonText: `Create End Product For Decision ${tabNumber + 1}`
    });
  }

  hasMultipleDecisions() {
    return this.props.task.appeal.decisions.length > 1;
  }

  buildIssueRow = (issue) => [
    issue.program,
    issue.description,
    issue.disposition
  ];

  render() {
    let {
      decisionType,
      handleCancelTask,
      handleCancelTaskForSpecialIssue,
      handleDecisionTypeChange,
      handleFieldChange,
      handleModalClose,
      handleSubmit,
      pdfLink,
      pdfjsLink,
      specialIssueModalDisplay,
      specialIssues,
      task
    } = this.props;

    let decisionDateStart = formatDate(addDays(new Date(task.appeal.decision_date), -3));
    let decisionDateEnd = formatDate(addDays(new Date(task.appeal.decision_date), 3));

    let issueType = (() => {
      if (decisionType.value === 'Remand' || decisionType.value === 'Partial Grant') {
        return SPECIAL_ISSUE_PARTIAL;
      }

      return SPECIAL_ISSUE_FULL;
    })();

    // Sort in reverse chronological order
    let decisions = task.appeal.decisions.sort((decision1, decision2) =>
      new Date(decision2.received_at) - new Date(decision1.received_at));

    let tabHeaders = decisions.map((decision, index) =>
      `Decision ${(index + 1)} (${formatDate(decision.received_at)})`);

    let pdfViews = decisions.map((decision, index) =>

      /* This link is here for 508 compliance, and shouldn't be visible to sighted
      users. We need to allow non-sighted users to preview the Decision. Adobe Acrobat
      is the accessibility standard and is used across gov't, so we'll recommend it
      for now. The usa-sr-only class will place an element off screen without
      affecting its placement in tab order, thus making it invisible onscreen
      but read out by screen readers. */
       <div>
          <a
            className="usa-sr-only"
            id="sr-download-link"
            href={`${pdfLink}&decision_number=${index}`}
            download
            target="_blank">
            The PDF viewer in your browser may not be accessible. Click to download
            the Decision PDF so you can preview it in a reader with accessibility features
            such as Adobe Acrobat.
          </a>
          <a className="usa-sr-only" href="#establish-claim-buttons">
            If you are using a screen reader and have downloaded and verified the Decision
            PDF, click this link to skip past the browser PDF viewer to the
            establish-claim buttons.
          </a>

          <iframe
            aria-label="The PDF embedded here is not accessible. Please use the above
              link to download the PDF and view it in a PDF reader. Then use the buttons
              below to go back and make edits or upload and certify the document."
            className="cf-doc-embed"
            title="Form8 PDF"
            src={`${pdfjsLink}&decision_number=${index}`}>
          </iframe>
        </div>);


    return (
      <div>
        <div className="cf-app-segment cf-app-segment--alt">
          <h2>Review Decision</h2>
          Review the final decision from VBMS below to determine the next step.
          {this.hasMultipleDecisions() && <div className="usa-alert usa-alert-warning">
            <div className="usa-alert-body">
              <div>
                <h3 className="usa-alert-heading">Multiple Decision Documents</h3>
                <p className="usa-alert-text">
                  We found more than one decision document for the dispatch date
                  range {decisionDateStart} - {decisionDateEnd}.
                  Please review the decisions in the tabs below and select the document
                  that best fits the decision criteria for this case.
                </p>
              </div>
            </div>
          </div>}
        </div>
        {this.hasMultipleDecisions() &&
          <div className="cf-app-segment cf-app-segment--alt">
            <h3>VACOLS Decision Criteria</h3>
            <Table
              headers={TABLE_HEADERS}
              buildRowValues={this.buildIssueRow}
              values={task.appeal.issues}
            />
          </div>}
        {

        /* This link is here for 508 compliance, and shouldn't be visible to sighted
         users. We need to allow non-sighted users to preview the Decision. Adobe Acrobat
         is the accessibility standard and is used across gov't, so we'll recommend it
         for now. The usa-sr-only class will place an element off screen without
         affecting its placement in tab order, thus making it invisible onscreen
         but read out by screen readers. */
        }
        <div className="cf-app-segment cf-app-segment--alt">
          {this.hasMultipleDecisions() && <div>
            <h2>Select a Decision Document</h2>
            <p>Use the tabs to review the decision documents below and
            select the decision that best fits the VACOLS Decision Criteria.</p>
            <TabWindow
              tabs={tabHeaders}
              pages={pdfViews}
              onChange={this.onTabSelected}/>
          </div>}
          {!this.hasMultipleDecisions() && pdfViews[0]}
          <DropDown
           label="Decision Type"
           name="decisionType"
           options={DECISION_TYPE}
           onChange={handleDecisionTypeChange}
           {...decisionType}
          />

          <label>Special Issue Categories</label>
          <div className="cf-multiple-columns">
            {

              /* eslint-disable no-return-assign */
              issueType.map((issue, index) => {
                return <Checkbox
                    id={ApiUtil.convertToCamelCase(issue)}
                    label={issue}
                    name={ApiUtil.convertToCamelCase(issue)}
                    onChange={handleFieldChange('specialIssues',
                        ApiUtil.convertToCamelCase(issue))}
                    key={index}
                    {...specialIssues[ApiUtil.convertToCamelCase(issue)]}
                  />
              })

                /* eslint-enable no-return-assign */
            }
          </div>
        </div>
        <div className="cf-app-segment" id="establish-claim-buttons">
          <div className="cf-push-right">
            <Button
                name="Cancel"
                onClick={handleCancelTask}
                classNames={["cf-btn-link", "cf-adjacent-buttons"]}
            />
            <Button
              name={this.state.endProductButtonText}
              onClick={handleSubmit}
            />
          </div>
        </div>

      {specialIssueModalDisplay && <Modal
        buttons={[
          { classNames: ["cf-modal-link", "cf-btn-link"],
            name: '\u00AB Close',
            onClick: handleModalClose('specialIssueModalDisplay')
          },
          { classNames: ["usa-button", "usa-button-secondary"],
            name: 'Cancel Claim Establishment',
            onClick: handleCancelTaskForSpecialIssue
          }
        ]}
        visible={true}
        closeHandler={handleModalClose('specialIssueModalDisplay')}
        title="Special Issue Grant">
        <p>
          You selected a special issue category not handled by AMO. Special
          issue cases cannot be processed in caseflow at this time. Please
          select <b>Cancel Claim Establishment</b> and proceed to process
          this case manually in VBMS.
        </p>
      </Modal>}
    </div>
    );
  }
}

EstablishClaimReview.propTypes = {
  decisionType: PropTypes.object.isRequired,
  handleCancelTaskForSpecialIssue: PropTypes.func.isRequired,
  handleDecisionTypeChange: PropTypes.func.isRequired,
  handleFieldChange: PropTypes.func.isRequired,
  handleModalClose: PropTypes.func.isRequired,
  handleSubmit: PropTypes.func.isRequired,
  pdfLink: PropTypes.string.isRequired,
  pdfjsLink: PropTypes.string.isRequired,
  specialIssueModalDisplay: PropTypes.bool.isRequired,
  specialIssues: PropTypes.object.isRequired,
  task: PropTypes.object.isRequired
};
