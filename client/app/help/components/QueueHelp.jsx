import React from 'react';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

class QueueHelp extends React.Component {

  render() {
    /* eslint-disable max-len */
    return <div className="cf-help-content">

      <p><Link href="/help">Go Back</Link></p>

      <h1 id="#top">Welcome to the Queue Help page!</h1>
      <p>Here you will find <a href="#training-videos"> Training Videos</a> and <a href="#faq"> Frequently Asked Questions (FAQs)</a> for Queue, as well as links to the Training Guide and the Quick Reference.
        These items are provided to assist you as you access and use Queue.
        If you require further assistance after reviewing these items, please contact the Caseflow team
        via the VA Enterprise Service Desk at 855-673-4357 or by creating a ticket
        via <a href="https://yourit.va.gov" target="_blank" rel="noopener noreferrer">YourIT</a>.
      </p>

      <h1 id="training-videos">Training Videos</h1>
      <div className="cf-help-divider"></div>

      <div className="cf-lead-paragraph">Coming Soon!</div>

      <h1 id="faq">Frequently Asked Questions</h1>

      <div className="cf-help-divider"></div>

      <ul id="toc" className="usa-unstyled-list">
        <li><a href="#what-is-caseflow-queue">1. What is Caseflow Queue?</a></li>
        <li><a href="#how-was-queue-developed">2. How was Queue developed?</a></li>
        <li><a href="#launch-queue">3. How do I launch Queue?</a></li>
        <li><a href="#queue-get-cases">4. Where does Queue get cases?</a></li>
        <li><a href="#veteran-data">5. Where does the Veteran and appeal data in Queue come from?</a></li>
        <li><a href="#cases-not-assigned-to-me">6. How can I see cases that are not assigned to me?</a></li>
        <li><a href="#encounter-problems">7. What should I do if I encounter problems?</a></li>
        <li><a href="#share-feedback">8. How do I share my suggestions for improving Queue?</a></li>
      </ul>

      <div className="cf-help-divider" />
      <h2 id="what-is-caseflow-queue">1. What is Caseflow Queue?</h2>

      <p>
        Caseflow Queue is a web-based workflow management tool designed to help manage and track
        appeals through the appeals process. It currently supports the legacy appeals process, and
        eventually will support the new appeals lanes and policies established by the Veterans Appeals
        Improvement and Modernization Act (AMA)
      </p>

      <h2 id="how-was-queue-developed">2. How was Queue developed?</h2>

      <p>
        The Digital Service at VA (DSVA) team worked closely with employees and other stakeholders
        at BVA, to develop and test a Queue prototype. Using feedback from VA employees and human centered
        design principles, DSVA has tweaked and improved the tool steadily, and will continue
        improving the tool as they collect more feedback from its users.
      </p>

      <h2 id="launch-queue">3. How do I launch Queue?</h2>

      <p>
        You can launch Queue by visiting the URL, <a href="https://appeals.cf.ds.va.gov/queue" target="_blank" rel="noopener noreferrer"> https://appeals.cf.ds.va.gov/queue</a>,
         in your Google Chrome browser and logging in with you VA credentials. You will be taken to the <b>Your Queue </b> page.
      </p>

      <h2 id="queue-get-cases">4. Where does Queue get cases?</h2>

      <p>
        Queue retrieves appeals assigned to you from the Decision Assignment Sheet (DAS).
      </p>

      <h2 id="veteran-data">5. Where does the Veteran and appeal data in Queue come from?</h2>

      <p>
        Caseflow retrieves Veteran and Queue data from VACOLS and displays it in Queue. Our hope is
        that you rely on Caseflow, rather than VACOLS or DAS, for this data.
      </p>

      <h2 id="cases-not-assigned-to-me">6. How can I see cases that are not assigned to me?</h2>

      <p>
       You can search for cases that are not assigned to you by entering a Veteran ID in the search bar
       in the top left of the screen. You will see all cases associated with that Veteran and can click on
       the Veteran’s name to get to that particular case’s details screen. From the case details screen,
       you can navigate to Reader to view the claims folder
      </p>

      <h2 id="encounter-problems">7. What should I do if I encounter problems?</h2>

      <p>Reviewing the FAQs or Training Guide may help you with most questions or issues. They may be accessed by clicking Help,
        located in the dropdown menu next to your username. However, If you encounter any problems while using Queue,
        feel free to send feedback using the "Send Feedback" link in the Help menu or the link at the bottom of the
        page. Additionally, you may contact the Caseflow Product Support Team by calling 1-844-876-5548 or sending an email to <a href="mailto: caseflow@va.gov">caseflow@va.gov</a>.
        They can be reached from 8:00AM to 8:00PM ET Monday through Friday.
      </p>

      <h2 id="share-feedback">8. How do I share my suggestions for improving Queue?</h2>

      <p>You can use the "Send feedback" link located in the dropdown menu next to your username, or the “Send feedback” link located at the bottom right-hand corner of the screen, to share your ideas for improving Queue.
      </p>

      <p className="cf-help-image-wrapper">
        <img className="cf-help-image" alt="Queue Feedback" src="/assets/help/reader-feedback.jpg" />
      </p>

    </div>;
    /* eslint-disable max-len */
  }
}

export default QueueHelp;
