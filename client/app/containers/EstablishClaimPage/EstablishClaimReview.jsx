import React, { PropTypes } from 'react';
import DropDown from '../../components/DropDown';
import Checkbox from '../../components/Checkbox';
import Modal from '../../components/Modal';

import ApiUtil from '../../util/ApiUtil';

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
  'Contaminated Water at Camp LeJeune',
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
    stationOfJurisdiction: '351 - Muskogee'
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
  render() {
    let {
      decisionType,
      handleCancelTaskForSpecialIssue,
      handleDecisionTypeChange,
      handleFieldChange,
      handleModalClose,
      pdfLink,
      pdfjsLink,
      specialIssueModalDisplay,
      specialIssues
    } = this.props;

    let count = 0;

    let issueType = '';

    if (decisionType.value === 'Remand' || decisionType.value === 'Partial Grant') {
      issueType = SPECIAL_ISSUE_PARTIAL;
    } else {
      issueType = SPECIAL_ISSUE_FULL;
    }

    return (
      <div>
        <div className="cf-app-segment cf-app-segment--alt">
          <h2>Review Decision</h2>
          Review the final decision from VBMS below to determine the next step.
        </div>
        {

        /* This link is here for 508 compliance, and shouldn't be visible to sighted
         users. We need to allow non-sighted users to preview the Decision. Adobe Acrobat
         is the accessibility standard and is used across gov't, so we'll recommend it
         for now. The usa-sr-only class will place an element off screen without
         affecting its placement in tab order, thus making it invisible onscreen
         but read out by screen readers. */
        }
        <a
          className="usa-sr-only"
          id="sr-download-link"
          href={pdfLink}
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
          className="cf-doc-embed cf-app-segment"
          title="Form8 PDF"
          src={pdfjsLink}>
        </iframe>
        <div className="cf-app-segment cf-app-segment--alt">
        <DropDown
         label="Decision Type"
         name="decisionType"
         options={DECISION_TYPE}
         onChange={handleDecisionTypeChange}
         {...decisionType}
        />

      <label>Special Issue Categories</label>
        {

          /* eslint-disable no-return-assign */
          issueType.map((issue) =>
          <Checkbox
              id={ApiUtil.convertToCamelCase(issue)}
              label={issue}
              name={ApiUtil.convertToCamelCase(issue)}
              {...specialIssues[issue]}
              onChange={handleFieldChange('specialIssues',
                  ApiUtil.convertToCamelCase(issue))}
              key={count += 1}
            />)

            /* eslint-enable no-return-assign */
        }
      </div>
      {specialIssueModalDisplay && <Modal
        buttons={[
          { classNames: ["cf-btn-link"],
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
  pdfLink: PropTypes.string.isRequired,
  pdfjsLink: PropTypes.string.isRequired,
  specialIssueModalDisplay: PropTypes.bool.isRequired,
  specialIssues: PropTypes.object.isRequired
};
