import React from 'react';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

class CertificationHelp extends React.Component {

  render() {
    /* eslint-disable max-len */
    return <div className="cf-help-content">

      <p><Link href="/help">Go Back</Link></p>

      <h1 id="#top">Welcome to the Reader Help page!</h1>

      <p>
        Here you will find <a href="#training-videos"> Training Videos</a> and <a href="#faq"> FAQs</a> for Reader.
        If you need help with a topic not covered on this page, please contact the Caseflow team
        via the VA Enterprise Service Desk at 855-673-4357 or by creating a ticket
        via <a href="https://yourit.va.gov" target="_blank" rel="noopener noreferrer">YourIT</a>.
      </p>

      <h1 id="training-videos">Training Videos</h1>
      <div className="cf-help-divider"></div>

      <div className="cf-lead-paragraph">Coming Soon!</div>

      <h1 id="faq">Frequently Asked Questions</h1>

      <div className="cf-help-divider"></div>

      <ul id="toc" className="usa-unstyled-list">
        <li><a href="#what-is-caseflow-reader">1. What is Caseflow Reader?</a></li>
        <li><a href="#how-was-reader-developed">2. How was Reader developed?</a></li>
        <li><a href="#how-to-access-reader">3. How do I access Reader?</a></li>
        <li><a href="#start-a-case">4. How do I start a case in Reader?</a></li>
        <li><a href="#where-documents-come-from">5. Where do the documents in Reader come from?</a></li>
        <li><a href="#view-virtual-va">6. Can I view Virtual VA documents in Reader?</a></li>
        <li><a href="#how-do-I-search-for-a-document">7. How do I search for a document in Reader?</a></li>
        <li><a href="#which-documents-I-have-read">8. How do I know which documents I have read on the claims folder page?</a><a></a></li><a>
        </a><li><a></a><a href="#open-document-in-separate-tab">9. How do I open a document in a separate tab?</a></li>
        <li><a href="#add-a-comment">10. How do I add a comment to a document in Reader?</a></li>
        <li><a href="#delete-comments-in-reader">11. How do I delete comments in Reader?</a></li>
        <li><a href="#how-do-issue-tags-work">12. How do issue tags work?</a></li>
        <li><a href="#sort-by-issue-tags">13. Can I sort documents by issue tags?</a></li>
        <li><a href="#complete-a-case">14. How do I complete a case in Reader?</a></li>
        <li><a href="#complete-a-review">15. What happens if I cannot complete a review in one sitting?</a></li>
        <li><a href="#encounter-problems">16. What should I do if I encounter problems?</a></li>
        <li><a href="#share-feedback">17. How do I share my feedback for improving Reader?</a></li>
        <li><a href="#need-help">18. What if I still need help?</a></li>
      </ul>
      <div className="cf-help-divider"></div>
      <h2 id="what-is-caseflow-reader">1. What is Caseflow Reader?</h2>
      <p>Caseflow Reader ("Reader") is a web-based tool for reviewing and annotating appellant claims folders. It was developed by the U.S. Digital Service at VA, and was custom built for the Board. The application allows you to navigate through all of the documents associated with a Veteran’s appeal, and to add categories, issue tags, and comments for fast and easy evidence review.
      </p>

      <h2 id="how-was-reader-developed">2. How was Reader developed?</h2>
      <p>The Digital Service at VA (DSVA) team worked closely with attorneys and judges at BVA and other stakeholders across the VA, to develop and test a Reader prototype. Using feedback from VA employees and human-centered design principles, DSVA has tweaked and improved the tool steadily, and will continue improving the tool as they collect more feedback from its users.
      </p>

      <h2 id="how-to-access-reader">3. How do I access Reader?</h2>
      <p>To gain access to Reader, you must submit a request to your Information Security Officer (ISO) and/or Information Resources Management (IRM) team to adjust your Common Security Employee Manager (CSEM) permissions. To initiate the request, draft an email requesting your current permissions be updated as follows:
      </p>

      <p className="cf-help-image-wrapper">
        <img className="cf-help-image" alt="Reader Access" src="/assets/help/reader-access.jpg" />
      </p>

      <p>Once the email is drafted, attach a copy of your latest “VA Privacy and Information Security Awareness and Rules of Behavior” training certificate and forward the email to your supervisor for approval. If approved, your supervisor should forward the request to your station’s IRM team and/or ISO for entry into CSEM. You will receive an email notice once access is granted.
      </p>

      <h2 id="start-a-case">4. How do I start a case in Reader?</h2>
      <p>To start a case using Reader, open Chrome and paste the following URL into the browser: <a href="http://appeals.cf.ds.va.gov/reader/appeal" target="_blank" rel="noopener noreferrer"> http://appeals.cf.ds.va.gov/reader/appeal </a>. Hit Enter and you will be taken to the Reader welcome page. Once on the Reader welcome page, you may select a case from the “Cases checked in” list.
      </p>

      <h2 id="where-documents-come-from">5. Where do the documents in Reader come from?</h2>
      <p>Reader retrieves documents from the VBMS eFolder.
      </p>

      <h2 id="view-virtual-va">6. Can I view Virtual VA documents in Reader?</h2>
      <p>No, you cannot currently access Virtual VA documents in Reader. This functionality may be available in the future.
      </p>

      <h2 id="how-do-I-search-for-a-document">7. How do I search for a document in Reader?</h2>
      <p>You can use the search bar on the claims folder page to locate specific documents by entering annotation keywords such as issue tag labels, categories, or comment text. You can also search for information about specific documents, such as the Document Type or Receipt Date; however, you cannot search within a document’s text from the search bar.
      </p>

      <h2 id="which-documents-I-have-read">8. How do I know which documents I have read on the claims folder page? </h2>
      <p>On the claims folder page, the Document Type will initially appear in bold. Once you have read the document, the text will appear in regular font. If a different attorney or judge opens the same case, the documents will reset to bold ("unread"). The categories, issue tags, comments, and annotations within the document will remain “as-is” if a different user views the document.
      </p>

      <h2 id="open-document-in-separate-tab">9. How do I open a document in a separate tab?</h2>
      <p>You can open a document in a new tab by selecting the Document Type link located at the top of the document in the PDF viewer (e.g., “Form 9” in screenshot below).
      </p>

      <p className="cf-help-image-wrapper">
        <img className="cf-help-image" alt="Reader Separate tab" src="/assets/help/reader-separate-tab.jpg" />
      </p>

      <h2 id="add-a-comment">10. How do I add a comment to a document in Reader?</h2>
      <p>Go to the page in the document where you would like to add a comment. In the Menu on the right-hand side, you will see a section called Comments where you can add, delete, edit, or read comments. Click on the "Add a comment" button and place the comment icon wherever you would like to add the comment by clicking on the document page. Type your comment in the dialog box that appears in the Comments section and click “Save.” Once added, comments can be dragged to different locations on the page. From the Documents List page, you can see how many comments have been added to a single document.
      </p>

      <h2 id="delete-comments-in-reader">11. How do I delete comments in Reader?</h2>
      <p>While reviewing a document, all of the comments are displayed in the Comments section in the Menu on the right-hand side. Each comment has its own "Delete" link above the comment box. Once you click the delete link, a confirmation box will appear. If you click the “Confirm delete” button, your comment box and icon will disappear.
      </p>

      <h2 id="how-do-issue-tags-work">12. How do issue tags work?</h2>
      <p>You can add issue tags to documents to help you label and filter documents by issues as you review evidence. The first time you create an issue tag, it will appear in the issue tags dropdown menu so you can easily add it to other documents. To add an issue tag to a document, click in the box under the Issue Tags section in the menu on the right-hand side and select an issue from the dropdown list or type an issue and hit Enter. You can delete an individual issue tag within a document by clicking the “X” next to the issue. Issue tags do not persist across cases.
      </p>

      <h2 id="sort-by-issue-tags">13. Can I sort documents by issue tags?</h2>
      <p>You can sort documents by issue tags by clicking on the filter icon next to the "Issue Tags” header on the claims folder page to filter documents by their associated issues. Selecting one or more issues tags will filter the documents to only display documents with the selected issues. You can return to the complete claims folder view by unchecking the selected issue tags.
      </p>

      <h2 id="complete-a-case">14. How do I complete a case in Reader?</h2>
      <p>After you complete a decision on an appeal, you should follow your regular process for sharing your decision document with your VLJ. If your VLJ has access to Reader, she/he will see your annotations when s/he opens the case in Reader.
      </p>

      <h2 id="complete-a-review">15. What happens if I cannot complete a review in one sitting?</h2>
      <p>Reader will automatically save any comments, categories, or issue tags you have added during the review process. The next time you access Reader you can pick up where you left off.
      </p>

      <h2 id="encounter-problems">16. What should I do if I encounter problems?</h2>
      <p>If you encounter any problems while using Reader, contact the Caseflow Support Team by calling 1-844-876-5548 or sending an email to <a href="mailto: caseflow@va.gov">caseflow@va.gov.</a>
      </p>

      <h2 id="share-feedback">17. How do I share my feedback for improving Reader?</h2>
      <p>You can use the "Send feedback" link located in the dropdown menu next to your username to share your ideas for improving Reader.
      </p>

      <p className="cf-help-image-wrapper">
        <img className="cf-help-image" alt="Reader Feedback" src="/assets/help/reader-feedback.jpg" />
      </p>

      <h2 id="need-help">18. What if I still need help?</h2>
      <p>If you still encounter issues or have questions that are not answered here, reach out to the Caseflow Product Support Team by calling 1-844-876-5548 or sending an email to <a href="mailto: caseflow@va.gov">caseflow@va.gov.</a>
      </p>

    </div>;
    /* eslint-disable max-len */
  }
}

export default CertificationHelp;
