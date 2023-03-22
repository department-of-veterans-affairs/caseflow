import React from 'react';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

class DispatchHelp extends React.Component {

  render() {
    /* eslint-disable max-len */
    return <div className="cf-help-content">

      <p><Link href="/help">Go Back</Link></p>

      <h1 id="#top">Welcome to the Dispatch Help page!</h1>
      <p>
        Here you will find <a href="#training-videos"> Training Videos</a> and <a href="#faq"> FAQs</a> for Dispatch. If you need help with a topic not covered on this page,
        please contact the Caseflow team via the VA Enterprise Service Desk at 855-673-4357
        or by creating a ticket
        via <a href="https://yourit.va.gov" target="_blank" rel="noopener noreferrer">YourIT</a>.
      </p>
      <h1 id="training-videos">Training Videos</h1>
      <div className="cf-help-divider"></div>

      <div className="cf-lead-paragraph">Coming Soon!</div>

      <h1 id="faq">Frequently Asked Questions</h1>

      <div className="cf-help-divider"></div>
      <ul id="toc" className="usa-unstyled-list">
        <li><a href="#what-is-caseflow-dispatch">1. What is Caseflow Dispatch?</a></li>
        <li><a href="#what-does-caseflow-dispatch-do">2. How was Dispatch developed? Who was involved?</a></li>
        <li><a href="#how-to-access">3. How do I access Dispatch?</a></li>
        <li><a href="#claims-assigned">4. How are claims assigned to me?</a></li>
        <li><a href="#how-many-claims">5. How do I know how many claims I have completed?</a></li>
        <li><a href="#veteran-information">6. Where does the Veteran information in the End Product (EP) form come from?</a></li>
        <li><a href="#work-history">7. What does the work history section represent?</a></li>
        <li><a href="#enter-own-document">8. Can I enter my own document type/EP options?</a></li>
        <li><a href="#&quot;send-claim&quot;">9. How do I send the claim to a particular RO?</a></li>
        <li><a href="#&quot;add-note&quot;">10. Can I add a note to the RO while in Dispatch?</a></li>
        <li><a href="#&quot;appeals-process&quot;">11. Are there any appeals that I can't process using Dispatch?
        </a></li><li><a href="#cancel-process">12. How can I cancel the process?</a></li>
        <li><a href="#select-wrong-special-issue">13. What happens if I accidentally select the wrong special issue or forget to select one?</a></li>
        <li><a href="#encounter-problems">14. What should I do if I encounter problems</a></li>
        <li><a href="#share-feedback">15. How do I share my feedback for improving Dispatch?</a></li>
        <li><a href="#need-help">16. What if I still need help?</a></li>
      </ul>
      <div className="cf-help-divider"></div>
      <h2 id="what-is-caseflow-dispatch">1. What is Caseflow Dispatch (or Dispatch)?</h2>

      <p>
      Caseflow Dispatch (or Dispatch) allows Claim Assistants at the Appeals Records Center (ARC) to create an End Product (EP) for almost every appeal that reaches the ARC. The EP is assigned to the ARC or to a Regional Office (RO)'s VBMS work queue if the case contains a special issue outside ARC's jurisdiction. Learn more: <a href="/dispatch_referenceGuide.pdf" target="_blank">Caseflow Dispatch Quick Reference Guide</a>
      </p>

      <h2 id="what-does-caseflow-dispatch-do">2. How was Dispatch developed? Who was involved?</h2>

      <p>The Digital Service team worked closely with the Appeals Record Center (ARC), the Appeals Management Office (AMO), and other stakeholders across the VA to develop and test Dispatch. Using feedback from VA employees and human-centered design principles, they have tweaked and improved the tool steadily. They will continue to improve the tool based on feedback and as they have more opportunities to make things simpler.
      </p>

      <h2 id="how-to-access">3. How do I access Dispatch?</h2>
      <p>
        Dispatch can be launched in any VA approved web browser, using this URL:<a href="https://appeals.cf.ds.va.gov/dispatch/establish-claim"> https://appeals.cf.ds.va.gov/dispatch/establish-claim</a>. Please confirm with your coach and your Information Security Officer that you are authorized to use Dispatch.
      </p>

      <h2 id="claims-assigned">4. How are claims assigned to me?</h2>
      <p>Dispatch automatically assigns you a pre-set number of claims for the day and routes the next claim in your station's work queue to you as you complete claims. Click "establish claim" to start the next claim in the queue.

      </p><h2 id="how-many-claims">5. How do I know how many claims I have completed?</h2>

      <p>The work history section provides a list of the claims that you have processed that day.
      </p>

      <h2 id="veteran-information">6. Where does the Veteran information in the End Product (EP) form come from?</h2>
      <p>The decision document that displays on the decision review page is pulled directly from VBMS and includes the final stamped decision date. The Veteran information that pre-populates the End Product page is pulled from both VBMS and VACOLS. Having this information pulled directly from these systems means that you do not need to check the systems again to verify the information included in the End Product, as you may have done in the past.
      </p>

      <h2 id="work-history">7. What does the work history section represent?</h2>

      <p>
      The work history section displays a list of claims that you have completed over the course of the day.
      </p>

      <h2 id="enter-own-document">8. Can I enter my own document type/EP options?</h2>

      <p>
      No, Dispatch pre-populates the decision type in order to streamline the decision review and delivery process.
      </p>

      <h2 id="send-claim">9. How do I send the claim to a particular RO?</h2>

      <p>Dispatch auto-assigns and sends the EP directly to the relevant RO's work queue based on the special issue or issues that have been selected during your review of the decision document.
      </p>

      <h2 id="add-note">10. Can I add a note to the RO while in Dispatch?</h2>

      <p>In the near term, Dispatch will provide you with a draft email message that you can send to the receiving RO to provide them with additional context about the EP. In the future, Dispatch will automatically notify the receiving RO with contextual information about the EP. You can also add a note for the receiving RO to the claim in VBMS as you may have done in the past.
      </p>

      <h2 id="appeals-process">11. Are there any appeals that I can't process using Dispatch?</h2>

      <p>
      You can process all appeals using Dispatch, regardless of the type of special issue.
      </p>

      <h2 id="cancel-process">12. How can I cancel the process?</h2>
      <p>You can cancel the process at any time by clicking on the Cancel link. If you have already created the End Product, you will need to manually cancel the End Product in VBMS as you would have done in the past.
      </p>

      <h2 id="select-wrong-special-issue">13. What happens if I accidentally select the wrong special issue or forget to select one?</h2>
      <p>If you notice you have selected the wrong special issue before you route the EP; you can go back to the Decision Review page, select the appropriate special issue, and continue routing the EP. If you have already created an EP (partial grant or remand) and it stays at ARC, you can enter VACOLS and make the required change. If you have already created an EP (full grant) and it is routed to a RO, your manager will have to broker the EP and forward an email.
      </p>

      <h2 id="encounter-problems">14. What should I do if I encounter problems?</h2>
      <p>If you encounter any problems while using Dispatch, you should ask your supervisor for assistance. If you are unable to resolve the issue, you can reach the Caseflow Support Team by calling 1-844-876-5548.
      </p>

      <h2 id="share-feedback">15. How do I share my feedback for improving Dispatch?</h2>
      <p>You can use the "Send feedback" link on the Dispatch home page to provide feedback directly to the Digital Service team. We appreciate your feedback.
      </p>

      <h2 id="need-help">16. What if I still need help?</h2>

      <p>If you still encounter issues or have questions that aren't answered here, reach out to the Caseflow Product Support Team by calling 1-844-876-5548.
      </p>
    </div>;
    /* eslint-disable max-len */
  }
}

export default DispatchHelp;

