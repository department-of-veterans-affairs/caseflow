import React from 'react';
import DropDown from '../../components/DropDown';

export const DECISION_TYPE = [
  'Remand',
  'Partial Grant',
  'Full Grant'
];

export const render = function() {
  let { pdfLink, pdfjsLink } = this.props;

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
        "The PDF viewer in your browser may not be accessible. Click to download
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

      <DropDown
       label="Select a Decision Type"
       name="decisionType"
       options={DECISION_TYPE}
       onChange={this.handleFieldChange('reviewForm', 'decisionType')}
       {...this.state.reviewForm.decisionType}
      />
    </div>
  );
};
