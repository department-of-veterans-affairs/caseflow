import React from 'react';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

class IntakeHelp extends React.Component {

  render() {
    /* eslint-disable max-len */
    return <div className="cf-help-content">

      <p><Link href="/help">Go Back</Link></p>

      <h1 id="#top">Welcome to the Intake Help page!</h1>

      <p>
      Here you will find <a href="#training-videos"> Training Videos</a> and <a href="#faq">Frequently Asked Questions
      (FAQs)</a> for Intake, as well as links to the&nbsp;
        <a target="_blank" rel="noopener noreferrer" href="/assets/Intake_Training_Guide.pdf">Training Guide</a> and the
        &nbsp;<a target="_blank" rel="noopener noreferrer" href="/assets/Intake_Quick_Reference_Guide.pdf">
      Quick Reference Guide</a>. These items are provided to assist you as you access and use Intake. If you require
      further assistance after reviewing these items, please contact&nbsp;
        <a href="https://yourit.va.gov" target="_blank" rel="noopener noreferrer">
        YourIT for support</a>. We look forward to assisting you.
      </p>

      <h1 id="training-videos">Training Videos</h1>
      <p>
        <a href="https://www.youtube.com/watch?v=kSQLLBVPgy0&feature=youtu.be" target="_blank" rel="noopener noreferrer">
      Training video for business lines other than compensation and pension
        </a>
      </p>
      <div className="cf-help-divider"></div>

      <div className="cf-lead-paragraph">Coming Soon!</div>

      <h1 id="faq">Frequently Asked Questions</h1>

      <div className="cf-help-divider"></div>

      <ul id="toc" className="usa-unstyled-list">
        <li><a href="#what-is-caseflow-intake">1. What is Caseflow Intake?</a></li>
        <li><a href="#how-was-intake-developed">2. How was Intake developed?</a></li>
        <li><a href="#how-to-access-intake">3. How do I access Intake?</a></li>
        <li><a href="#launch-intake">4. How do I launch Intake?</a></li>
        <li><a href="#web-browser">5. Which web browser can I use with Intake?</a></li>
        <li><a href="#telecommuting">6. Does Intake work while I am telecommuting?</a></li>
        <li><a href="#encounter-problems">7. What should I do if I encounter problems?</a></li>
        <li><a href="#suggestions">8. How can I share my suggestions for improving Intake?</a><a></a></li><a>
        </a><li><a></a><a href="#still-need-help">9. What if I still need help? </a></li>
      </ul>

      <div className="cf-help-divider"></div>

      <h2 id="what-is-caseflow-intake">1. What is Caseflow Intake?</h2>
      <p>
      Caseflow Intake (Intake) is a web-based application designed to support the Appeals Modernization Act (AMA).
      Used to process AMA appeals for Veterans who have chosen the new Supplemental Claim (SC) or Higher-Level Review
      (HLR) options as well as those who have chosen to appeal directly to the Board through a Notice of Disagreement
      (NOD). Intake serves as the single data input system for this process, providing a source of truth for AMA
      statutory metrics. For VBMS users, Intake creates an End Product (EP), route the EP to the appropriate
      destination, and close the VACOLS record automatically for eligible legacy opt-ins. Intake also guides Claims
      Assistants (CAs) through the process of notifying Veterans, updating necessary systems, and creating EPs.
      </p>

      <p>
      For non-VBMS users, Intake also provides a lightweight task list and facility to mark dispositions,
      closing the loop on appeals issues and assuring an end-to-end collection of AMA metrics. Across the board,
      Intake performs numerous issue-level validations, matching, and error checking, to capture the best possible
      data and reduce processing overhead.

      </p>

      <p>
       Learn more: <a target="_blank" rel="noopener noreferrer" href="/assets/Intake_Training_Guide.pdf">
       Training Guide</a>
      </p>

      <h2 id="how-was-intake-developed">2. How was Intake developed?</h2>
      <p>
      The DSVA team worked closely with stakeholders across the VA to develop and test Intake.
      Using feedback from VA employees and human-centered design principles, DSVA has tweaked
      and improved the tool steadily. They will continue to improve the tool based on feedback and as
      they have more opportunities to make things simpler.
      </p>

      <h2 id="how-to-access-intake">3. How do I access Intake?</h2>
      <p>
      Each business line has identified a <strong>Caseflow Administrator</strong>, who acts as the point of contact
      for Caseflow issues for their line of business.
      </p>

      <p><strong>To gain access to Intake, your Caseflow Administrator must submit a request including:</strong></p>

      <h3>User Access List Submission</h3>
      <p>
      Please contact <a href="https://yourit.va.gov" target="_blank" rel="noopener noreferrer">YourIT</a> requesting
       access to Caseflow and provide a list of users with credential information (Name, Email, Station, and User ID).
      </p>

      <h3>Users may require Documents Submission (If requested)</h3>
      <p>
      Users not currently in CSEM may require documentation which includes TMS Certificates, access forms, and/or
      Credentialing Information. Have your group's POC alert the users.
      </p>

      <p className="cf-red-text">
      The Caseflow support team does not have access to view CSEM access requests and therefore cannot provide the
      status of a user’s access. Users will be directed to contact their Caseflow Administrator for more information.
      </p>

      <h2 id="launch-intake">4. How do I launch Intake?</h2>
      <h3>For Compensation and Pension Lines of Business</h3>
      <p>To launch Intake, open your web browser and paste the following URL into the address bar:&nbsp;
        <a href="https://appeals.cf.ds.va.gov/intake" >https://appeals.cf.ds.va.gov/intake</a>. Hit the Enter button
      and sign in using your VA credentials. You will be taken to the Intake Welcome page.
      </p>

      <h3>For Non-Compensation / Non-Pension Lines of Business</h3>
      <p>The URL for your Line of Business will be provided to you.</p>

      <h2 id="web-browser">5. Which web browser can I use with Intake?</h2>
      <p>The latest version of Google Chrome and Internet Explorer are recommended for Caseflow Intake.
      </p>

      <h2 id="telecommuting">6. Does Intake work while I am telecommuting?</h2>
      <p>Yes, you can use Intake while connected to the VA network via VPN.
      </p>

      <h2 id="encounter-problems">7. What should I do if I encounter problems?</h2>
      <p>
      If you encounter any problems while using Intake, please contact&nbsp;
        <a href="https://yourit.va.gov" target="_blank" rel="noopener noreferrer">YourIT for support</a>.
      </p>

      <h2 id="suggestions">8. How can I share my suggestions for improving Intake?</h2>
      <p>
      You can use the "Send feedback" link located in the dropdown menu next to your username or
      the “Send feedback” link located at the bottom right-hand corner of the screen to share your
      ideas for improving Intake or to report an issue.
      </p>

      <p className="cf-help-image-wrapper">
        <img className="cf-help-image" alt="Send Intake Feedback" src="/assets/intake-feedback.jpg" />
      </p>

      <h2 id="still-need-help">9. What if I still need help?</h2>
      <p>
      If you require further assistance after reviewing the <a href="#faq">FAQs</a>,&nbsp;
        <a target="_blank" rel="noopener noreferrer" href="/assets/Intake_Quick_Reference_Guide.pdf">Quick Reference
      Guide</a>, or <a target="_blank" rel="noopener noreferrer" href="/assets/Intake_Training_Guide.pdf">Training Guide
        </a>, please contact&nbsp;
        <a href="https://yourit.va.gov" target="_blank" rel="noopener noreferrer">
        YourIT for support</a>. We look forward to assisting you.
      </p>

    </div>;
    /* eslint-disable max-len */
  }
}

export default IntakeHelp;
