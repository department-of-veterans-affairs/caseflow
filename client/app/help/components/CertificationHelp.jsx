import React from 'react';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

class CertificationHelp extends React.Component {

  render() {
    /* eslint-disable max-len */
    return <div className="cf-help-content">

      <p><Link href="/help">Go Back</Link></p>

      <h1>Welcome to the Certification Help page!</h1>
      <p>Here you will find <a href="#training-videos"> Training Videos</a> and <a href="#faq"> Frequently Asked Questions (FAQs)</a> for Certification, as well as links to the <a target="_blank" href="/assets/certificationV2_trainingguide-adb1cf699372fb0f9730fbff6d476d3751bf06077d3b09feae376670439dfce0.pdf">Training Guide</a> and the  <a target="_blank" href="/assets/certificationV2_quickreference-076e9b955b964f4fe8d2f164b5c898f77a0b389a4b018312256700e9ee718d2c.pdf">Quick Reference</a>. These items are provided to assist you as you access and use Certification. If you require further assistance after reviewing these items, please contact the Caseflow Product Support Team by phone (1-844-876-5548) or email <a href="mailto:caseflow@va.gov">(caseflow@va.gov)</a>. We look forward to assisting you.
      </p>
      <h1 id="faq">Frequently Asked Questions</h1>
      <div className="cf-help-divider"></div>
      <ul id="toc" className="usa-unstyled-list">
        <li><a href="#what-is-caseflow">1. What is Caseflow Certification?</a></li>
        <li><a href="#what-does-caseflow-do">2. What does Caseflow Certification do?</a></li>
        <li><a href="#how-to-launch">3. How do I launch Caseflow Certification?</a></li>
        <li><a href="#how-to-login">4. How do I log in to Caseflow Certification?</a></li>
        <li><a href="#cannot-find-documents">5. Why does Caseflow say it cannot find documents in the appellant’s eFolder?</a></li>
        <li><a href="#mismatched-documents">6. What are the reasons Caseflow may not be able to find documents in VBMS?</a></li>
        <li><a href="#multiple-document-types">7. What should I do if an eFolder document contains multiple types of information?</a></li>
        <li><a href="#electronic-form8">8. How do I fill out an electronic Form 8?</a></li>
        <li><a href="#preview-form8">9. What is the Preview Form 8 page?</a></li>
        <li><a href="#upload-and-certify">10. What happens when I click the&nbsp;Upload and Certify&nbsp;button?</a></li>
        <li><a href="#encounter-problem">11. What if I encounter a problem that prevents me from certifying the appeal?</a></li>
        <li><a href="#need-help">12. What do I do if I need help?</a></li>
        <li><a href="#paper-appeals">13. How do I certify paper appeals?</a></li>
        <li><a href="#virtual-va">14. What if my appeal has the Form 9, NOD, SOC, and/or SSOC in Virtual VA?</a></li>
        <li><a href="#no-va646">15. What if my appeal does not have a completed VA-646 form?</a></li>
        <li><a href="#notification-letters">16. How should I send out notification letters after I’ve certified the appeal?</a></li>
        <li><a href="#merged-appeals">17. Can I use Caseflow Certification with appeals that have been merged together?</a></li>
        <li><a href="#remanded-appeals">18. Should I use Caseflow to process remanded appeals?</a></li>
        <li><a href="#software-updates">19. When will you update Caseflow Certification?</a></li>
        <li><a href="#more-help">20. What if I still need help?</a></li>
      </ul>
      <div className="cf-help-divider"></div>

      <h2 id="what-is-caseflow">1. What is Caseflow Certification?</h2>

      <p>
    Caseflow Certification is a web-based tool that streamlines the certification process by
    checking case documents for readiness and ensuring accuracy of the Veteran’s representative
    and hearing preferences. The tool was built by the United States Digital Service at the
    Department of Veterans Affairs, in close collaboration with Decision Review Officers and
    other employees in VA regional offices all over the country. Learn more:
        <a target="_blank" href="/assets/certificationV2_trainingguide-adb1cf699372fb0f9730fbff6d476d3751bf06077d3b09feae376670439dfce0.pdf">Training Guide</a>
      </p>

      <h2 id="what-does-caseflow-do">2. What does Caseflow Certification do?</h2>
      <p>
    Caseflow eliminates the need to fill out a PDF Form 8 for appeals. It
    automatically checks to make sure documents such as the VA Form 9, Notice of
    Disagreement (NOD), Statement of Case (SOC), and Supplemental Statements of
    Case (SSOC) have been added to an appeal. It also verifies that these documents
    are consistent between VBMS and VACOLS. Once verified, the tool lets you fill
    out an electronic Form 8. It automatically pre-fills some of the Form 8 data
    from VACOLS and VBMS. It will then generate a PDF of the Form 8 and allow you
    to easily upload that document to the VBMS eFolder.

    You should use Caseflow with paperless appeals that are ready to be certified.
      </p>

      <h2 id="how-to-launch">3. How do I launch Caseflow Certification?</h2>

      <p>
    Once you are ready to certify an appeal, open and log in to VACOLS then search
    for the Appeal ID. Once the date for the Form 9, NOD, SOC, and any required
    SSOC have been entered into VACOLS, click the Certify Appeal button from the
    process menu. You can also select this option from the search results window or
    the update appeal window.
      </p>

      <p className="cf-help-image-wrapper">
        <img className="cf-help-image" alt="VACOLS Processes dialog" src="/assets/help/vacols-processes.jpg" />
      </p>

      <h2 id="how-to-login">4. How do I log in to Caseflow Certification?</h2>

      <p>
      If it&apos;s the first time you are using Caseflow Certification in a while you wll be
      asked to log in twice. The first time you wll want to log in using your standard VA
      credentials (or PIV if you like). On the second login page, you will need to log
      in using your regional office VACOLS credentials.

      </p>
      <p className="cf-help-image-wrapper">
        <img className="cf-help-image" alt="VACOLS Login dialog" src="/assets/help/caseflow-login.jpg" />
      </p>
      <h2 id="cannot-find-documents">5. Why does Caseflow say it cannot find documents in the appellant’s
      eFolder?</h2>

      <p>
      Once you are re logged in, Caseflow will check to see if documents in the VBMS eFolder (such as the NOD, SOC, and Form 9)
      match the dates entered in VACOLS. Caseflow will tell you if it cannot find these documents in VBMS.
      </p>

      <p className="cf-help-image-wrapper">
        <img className="cf-help-image" alt="Caseflow mismatched documents dialog" src="/assets/help/caseflow-mismatched_v2.jpg" />
      </p>

      <p>
      Document dates in VBMS and VACOLS for the NOD and Form 9 must match exactly. Document dates for the SOC and SSOC are
      considered matching if the VBMS date is no more than 4 days ahead of the VACOLS date.
      </p>

      <h2 id="mismatched-documents">6. What are the reasons Caseflow may not be able to find documents in VBMS? </h2>

      <p>
      There are usually three reasons Caseflow wouldn&apos;t be able to find a document:

      </p><h3>1. The dates of the document in question are inconsistent between VACOLS and VBMS.</h3>

      <p>
If the dates are inconsistent, change the date in either VACOLS or VBMS to match the other, then click the
"Refresh page" button in Caseflow. If the date cannot be changed in VBMS, change the date in VACOLS.
      </p>

      <p>
Document dates in VBMS and VACOLS for the NOD and Form 9 must match exactly. Document dates for the SOC and SSOC
are considered matching if the VBMS date is no more than 4 days ahead of the VACOLS date. There is a wider range
of acceptable dates for SOCs and SSOCs because SOCs and SSOCs may be uploaded to VBMS one or more days before they
are mailed, causing VBMS dates to be earlier than VACOLS dates.
      </p>

      <h3>2. The label of the document in question is missing or incorrect in VBMS</h3>

      <p>
    If a document is missing a label or uses something other than one of the labels
    listed below, you should add correct label to the document in the VBMS document
    settings and click the refresh&nbsp;button in Caseflow.
      </p>

      <h3>3. If a document is missing from the eFolder, the appeal cannot be certified using Caseflow and should instead be certified manually.</h3>

      <p>
    If a document is missing a label or uses something other than one of the labels
    listed below, you should add the correct label to the document in the VBMS document
    settings and click the refresh&nbsp;button in Caseflow.
      </p>

      <ol>
        <li>Statement of Case (SOC)</li>
        <li>Notice of Disagreement</li>
        <li>Supplemental Statement of Case (SSOC)</li>
        <li>VA 9 Appeal to Board of Appeals</li>
        <li>The document in question has not been uploaded to VBMS.</li>
      </ol>

      <p>
    If a document is missing from the eFolder, the appeal is not ready to be
    certified and you should click the&nbsp;Cancel Certification&nbsp;button.
      </p>

      <p className="cf-help-image-wrapper">
        <img className="cf-help-image" alt="VBMS document properties dialog" src="/assets/help/vbms-documentproperties.jpg" />
      </p>

      <h2 id="multiple-document-types">7. What should I do if an eFolder document contains multiple
    types of information?</h2>

      <p>
    Occasionally, especially with older appeals, an NOD or a Form 9 will be
    included in a document with a more general label such as a Statement in Support
    of Claim. These documents could contain other information such as testimony or
    evidence. Add the appropriate labels from those listed in question 6 to the newly uploaded
    document and make sure the date matches the one listed in VACOLS.
      </p>

      <p className="cf-help-image-wrapper">
        <img className="cf-help-image" alt="Add correct doc label in VBMS" src="/assets/help/vbms-addlabel.jpg" />
      </p>

      <h2 id="electronic-form8">8. How do I fill out an electronic Form 8?</h2>

      <p>
    Once all the documents are detected, you will see a web form that lets you fill
    out all the details to complete a Form 8. A red asterisk
    (<span className="required"><strong></strong></span>) marks required questions.

    To make things go a little faster, some of the fields are automatically
    pre-filled using data from VBMS and VACOLS. If something is pre-filled but
    doesn&apos;t look right, you can always manually correct the data on this page.

    You will also notice that some questions are only shown if relevant. For example,
    question 10b, "Is the hearing transcript in file?" only shows up if you
    indicate that a hearing was held.

    Once you have finished filling out all the relevant details on this page, click
    the&nbsp;Preview Completed Form 8 button.
      </p>

      <h2 id="preview-form8">9. What is the Preview Form 8 page?</h2>

      <p>
    This page allows you to preview the completed Form 8. If anything looks wrong
    you can click the&nbsp;Go back and make edits&nbsp;button to fix the problem on the
    previous page. If, after review, the Form 8 looks correct, click the&nbsp;Upload and
    Certify&nbsp;button.
      </p>

      <h2 id="upload-and-certify">10. What happens when I click the&nbsp;Upload and Certify&nbsp;button?</h2>

      <p>
    The Form 8 will automatically be uploaded to the eFolder, a certification date
    will be added to the appeal, and the appeal will be certified to the Board of
    Veterans Appeals!  Once you see the "Congratulations" page you can close the
    browser window and open up another appeal using VACOLS. Please keep in mind that you should
    continue to follow existing procedures for dispatching the Form 8 to the Board and sending
    the "File Certified to BVA" letter to the claimant, after the Form 8
    has been uploaded to VBMS.

    Behind the scenes, Caseflow fills in the date for the "BVA Cert Date" field in VACOLS. If you have
    selected that the appellant requests a Travel Board Hearing in VACOLS previously, Caseflow checks
    the "Ready" box in the Travel Board section. You can see both of these fields in the screenshot
    below.

      </p><p className="cf-help-image-wrapper">&nbsp;&nbsp;&nbsp; <img className="cf-help-image" alt="vacols travel board" src="/assets/help/vacols-travelboard.jpg" />&nbsp;
      </p>
      <h2 id="encounter-problem">11. What if I encounter a problem that prevents me from
      certifying the appeal?</h2>

      <p>
      Prior to clicking Upload and Certify, you can cancel out of the certification process at any
      time by clicking the cancel button. A modal will appear, asking you to confirm your cancellation.
      </p>

      <p>
      </p><p className="cf-help-image-wrapper">
        <img className="cf-help-image" alt="Caseflow Cancel Modal" src="/assets/help/caseflow-cancelmodal.jpg" />
      </p>

      <p>
If you have already clicked Upload and Certify, you will need to manually remove the Form 8
from VBMS and then clear the Certification date in the VACOLS "utilities menu" in order to
cancel the certification.
      </p>

      <p>
      </p><p className="cf-help-image-wrapper">
        <img className="cf-help-image" alt="Clear Certification date in VACOLS" src="/assets/help/vacols-cleardate.jpg" />
      </p>

      <h2 id="need-help">12. What do I do if I need help?</h2>

      <p>
If you need help remembering how to use Caseflow Certification and want to get
back to these instructions, you can click the dropdown menu in the top right of
Caseflow and select the Help&nbsp;option.
      </p>

      <h2 id="paper-appeals">13. How do I certify paper appeals?</h2>

      <p>
You can only certify paperless appeals with Caseflow Certification. If you have
a paper appeal, you will have to manually fill out a Form 8. Once it&apos;s completed,
find the appeal in VACOLS, click the Certify button, then select the Hardcopy
claims folder or Virtual VA option. From here you will need to manually fill out
a Form 8 for the appeal and type in the Certification Date this window.
      </p>

      <p>
      </p><p className="cf-help-image-wrapper">
        <img className="cf-help-image" alt="Caseflow Cancel Modal" src="/assets/help/vacols-certify.jpg" />
      </p>

      <h2 id="virtual-va">14. What if my appeal has the Form 9, NOD, SOC, and/or SSOC in Virtual VA?</h2>

      <p>
Caseflow Certification does not work with appeals where the Form 9, NOD, SOC,
or SSOC are stored in Virtual VA. If, in the rare case, you have an appeal that
has these specific documents in a Virtual VA, you will have to manually fill out
and upload a regular Form 8 and manually enter the Certification Date in
VACOLS. Once the Form 8 is completed, open the appeal in VACOLS, click the
Certify button, and select the Hardcopy claims folder or Virtual VA option. Please keep in mind
that you should continue to follow existing procedures for sending the "File Certified to BVA" letter
after the Form 8 has been uploaded to VBMS.

      </p>

      <h2 id="no-va646">15. What if my appeal does not have a completed VA-646 form?</h2>

      <p>
VA Form 646 is not a mandatory part of the Certification process to the Board and therefore
will not prevent you from certifying the case.
      </p>

      <h2 id="notification-letters">16. How should I send out notification letters after I’ve certified
the appeal?</h2>

      <p>
At this time, you’ll need to use your current procedures to send letters to the
appellant, representative or others involved in the appeal. We’ve received
feedback that this is a burdensome process and we’re working on a way to
automate this.
      </p>

      <h2 id="merged-appeals">17. Can I use Caseflow Certification with appeals that have been merged
together?</h2>

      <p>
Yes! When an appeal is merged, VACOLS uses the oldest appeals document dates
(NOD, SOC, Form 9 dates). Caseflow works off of the date entered in VACOLS. So
if there were multiple Form 9s, Caseflow would look for the oldest Form 9 for
the appeal, just as employees at the Board do today.
      </p>

      <h2 id="remanded-appeals">18. Should I use Caseflow to process remanded appeals?</h2>

      <p>
At this time, you do not need to use Caseflow to process remands because the
appeal will already be certified and have a completed VA-Form 8. You should
continue to follow existing procedures to process remands.
      </p>

      <h2 id="software-updates">19. When will you update Caseflow Certification?</h2>
      <p>
Caseflow Certification will continue to be improved and any feedback that you
submit will be directly received and reviewed by our team.
      </p>

      <h2 id="more-help">20. What if I still need help?</h2>

      <p>
If you require further assistance after viewing the <a href="#faq">FAQs</a>, <a target="_blank" href="/assets/certificationV2_quickreference-076e9b955b964f4fe8d2f164b5c898f77a0b389a4b018312256700e9ee718d2c.pdf">Quick Reference</a> or <a target="_blank" href="/assets/certificationV2_trainingguide-adb1cf699372fb0f9730fbff6d476d3751bf06077d3b09feae376670439dfce0.pdf">Training Guide</a>, please contact the Caseflow Product Support Team by phone (1-844-876-5548) or email <a href="mailto:caseflow@va.gov">(caseflow@va.gov)</a>. We look forward to assisting you.
      </p>
    </div>;
    /* eslint-disable max-len */
  }
}

export default CertificationHelp;
