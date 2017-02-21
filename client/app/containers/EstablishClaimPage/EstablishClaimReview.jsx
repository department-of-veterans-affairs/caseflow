import React, { PropTypes } from 'react';
import TextField from '../../components/TextField';
import Checkbox from '../../components/Checkbox';
import Modal from '../../components/Modal';
import Button from '../../components/Button';
import { formatDate, addDays } from '../../util/DateUtil';
import StringUtil from '../../util/StringUtil';
import Table from '../../components/Table';
import TabWindow from '../../components/TabWindow';

const TABLE_HEADERS = ['Program', 'VACOLS Issue(s)', 'Disposition'];

export const DECISION_TYPE = [
  'Full Grant',
  'Partial Grant',
  'Remand'
];

export const SPECIAL_ISSUES = [
  'Contaminated Water at Camp LeJeune',
  'DIC - death, or accrued benefits - United States',
  `Education - GI Bill, dependents educational ` +
    `assistance, scholarship, transfer of entitlement`,
  'Foreign claim - compensation claims, dual claims, appeals',
  'Foreign pension, DIC - Mexico, Central and South American, Caribbean',
  'Foreign pension, DIC - all other foreign countries',
  'Hearing - including travel board & video conference',
  'Home Loan Guarantee',
  'Incarcerated Veterans',
  'Insurance',
  'Manlincon Compliance',
  'Mustard Gas',
  'National Cemetery Administration',
  'Non-rating issue',
  'Pension - United States',
  'Private Attorney or Agent',
  'Radiation',
  'Rice Compliance',
  'Spina Bifida',
  `U.S. Territory claim - American Samoa, Guam, Northern ` +
    `Mariana Islands (Rota, Saipan & Tinian)`,
  'U.S. Territory claim - Philippines',
  'U.S. Territory claim - Puerto Rico and Virgin Islands',
  'VAMC',
  'Vocational Rehab',
  'Waiver of Overpayment'
];


const SPECIAL_ISSUE_NODE_MAP = {
  'Manlincon Compliance': <span><i>Manlincon</i> Compliance</span>,
  'Rice Compliance': <span><i>Rice</i> Compliance</span>
};

export const UNHANDLED_SPECIAL_ISSUES = [
  {
    emailAddress: 'PMC',
    regionalOffice: 'PMC',
    specialIssue: 'dicDeathOrAccruedBenefitsUnitedStates'
  },
  {
    emailAddress: 'education',
    regionalOffice: 'education',
    specialIssue: 'educationGiBillDependentsEducational' +
    'AssistanceScholarshipTransferOfEntitlement'
  },
  {
    emailAddress: ['PMC/PMCIPC.VAVBASPL@va.gov', 'Hillary.Hernandez@va.gov'],
    regionalOffice: 'RO83',
    specialIssue: 'foreignPensionDicMexicoCentralAndSouthAmericanCaribbean'
  },
  {
    emailAddess: 'PMC',
    regionalOffice: 'PMC',
    specialIssue: 'foreignPensionDicAllOtherForeignCountries'
  },
  {
    emailAddress: [],
    regionalOffice: '',
    specialIssue: 'homeLoanGuarantee'
  },
  {
    emailAddress: ['nancy.encarnado@va.gov'],
    regionalOffice: 'RO80',
    specialIssue: 'insurance'
  },
  {
    emailAddress: [],
    regionalOffice: '',
    specialIssue: 'nationalCemeteryAdministration'
  },
  {
    emailAddress: 'PMC',
    regionalOffice: 'PMC',
    specialIssue: 'pensionUnitedStates'
  },
  {
    emailAddress: ['Travis.Richardson@va.gov'],
    regionalOffice: 'RO99',
    specialIssue: 'vamc'
  },
  {
    emailAddress: [],
    regionalOffice: '',
    specialIssue: 'vocationalRehab'
  },
  {
    emailAddress: 'COWC',
    regionalOffice: 'COWC',
    specialIssue: 'waiverOfOverpayment'
  }
];

export const ROUTING_SPECIAL_ISSUES = [
  {
    specialIssue: 'mustardGas',
    stationOfJurisdiction: '351 - Muskogee, OK'
  },
  {
    specialIssue: 'contaminatedWaterAtCampLejeune',
    stationOfJurisdiction: '327 - Louisville, KY'
  },
  {
    specialIssue: 'foreignClaimCompensationClaimsDualClaimsAppeals',
    stationOfJurisdiction: '311 - Pittsburgh, PA'
  },
  {
    specialIssue: 'usTerritoryClaimPhilippines',
    stationOfJurisdiction: '358 - Manila, Philippines'
  },
  {
    specialIssue: 'usTerritoryClaimPuertoRicoAndVirginIslands',
    stationOfJurisdiction: '355 - San Juan, Puerto Rico'
  },
  {
    specialIssue: 'usTerritoryClaimAmericanSamoaGuamNorthern' +
      'MarianaIslandsRotaSaipanTinian',
    stationOfJurisdiction: '459 - Honolulu, HI'
  }
];

export const REGIONAL_OFFICE_SPECIAL_ISSUES = [
  `educationGiBillDependentsEducational` +
    `AssistanceScholarshipTransferOfEntitlement`,
  'hearingIncludingTravelBoardVideoConference',
  'homeLoanGuarantee',
  'incarceratedVeterans',
  'manlinconCompliance',
  'nonratingIssue',
  'privateAttorneyOrAgent',
  'radiation',
  'riceCompliance',
  'spinaBifida'
];

export default class EstablishClaimReview extends React.Component {
  constructor(props) {
    super(props);
    let endProductButtonText;

    if (this.hasMultipleDecisions()) {
      endProductButtonText = "Route Claim for Decision 1";
    } else {
      endProductButtonText = "Route Claim";
    }
    this.state = {
      endProductButtonText
    };
  }

  onTabSelected = (tabNumber) => {
    this.setState({
      endProductButtonText: `Route Claim for Decision ${tabNumber + 1}`
    });
  }

  hasMultipleDecisions() {
    return this.props.task.appeal.decisions.length > 1;
  }

  buildIssueRow = (issue, index) => {
    let description = issue.description.map((descriptor) =>
      <div key={`${descriptor}-${index}`}>{descriptor}</div>, null);

    return [
      issue.program,
      <div>{description}</div>,
      issue.disposition
    ];
  }

  render() {
    let {
      decisionType,
      handleCancelTask,
      handleCancelTaskForSpecialIssue,
      handleFieldChange,
      handleModalClose,
      handleSubmit,
      pdfLink,
      pdfjsLink,
      specialIssueModalDisplay,
      specialIssues,
      task
    } = this.props;

    let decisionDateStart = formatDate(
      addDays(new Date(task.appeal.serialized_decision_date), -3)
    );

    let decisionDateEnd = formatDate(
      addDays(new Date(task.appeal.serialized_decision_date), 3)
    );

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
          <TextField
           label="Decision Type"
           name="decisionType"
           readOnly={true}
           {...decisionType}
          />

          <label><b>Select Special Issue(s)</b></label>
          <div className="cf-multiple-columns">
            {
              SPECIAL_ISSUES.map((issue, index) => {
                let issueName = StringUtil.convertToCamelCase(issue);
                let node = SPECIAL_ISSUE_NODE_MAP[issue] || issue;

                return <Checkbox
                  id={issueName}
                  label={node}
                  name={issueName}
                  onChange={handleFieldChange('specialIssues', issueName)}
                    key={index}
                    {...specialIssues[issueName]}
                />;
              })
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
  handleFieldChange: PropTypes.func.isRequired,
  handleModalClose: PropTypes.func.isRequired,
  handleSubmit: PropTypes.func.isRequired,
  pdfLink: PropTypes.string.isRequired,
  pdfjsLink: PropTypes.string.isRequired,
  specialIssueModalDisplay: PropTypes.bool.isRequired,
  specialIssues: PropTypes.object.isRequired,
  task: PropTypes.object.isRequired
};
