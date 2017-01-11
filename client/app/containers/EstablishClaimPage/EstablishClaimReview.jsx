import React from 'react';
import DropDown from '../../components/DropDown';
import Checkbox from '../../components/Checkbox';

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
  'DIC = death, or accrued benefits',
  'Foreign Claims',
  'Education or Vocational Rehab',
  'Waiver of Overpayment',
  'National Cemetery Administration'
]

export const render = function() {
  let { pdfLink, pdfjsLink } = this.props;

  let count = 0;

  let issueType = '';

  if (this.state.reviewForm.decisionType.value === 'Remand' ||
  this.state.reviewForm.decisionType.value === 'Partial Grant') {
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
       onChange={this.handleFieldChange('reviewForm', 'decisionType')}
       {...this.state.reviewForm.decisionType}
      />

    <label>Special Issue Categories</label>
      {
        /* eslint-disable no-return-assign */
        issueType.map((issue) =>
        <Checkbox
            label={issue}
            name={issue.split(' ').join('')}
            {...this.state.specialIssues[issue]}
            onChange={this.handleFieldChange('specialIssues', issue.split(' ').join(''))}
            key={count += 1}
          />)
          /* eslint-enable no-return-assign */
      }
    </div>
  </div>
  );
};
