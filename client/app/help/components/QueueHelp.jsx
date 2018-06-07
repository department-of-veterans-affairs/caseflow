import React from 'react';

class QueueHelp extends React.Component {

  render() {
    /* eslint-disable max-len */
    return <div className="cf-help-content">
      <h1 id="#top">Welcome to the Queue Help page!</h1>
      <p>Here you will find <a href="#training-videos"> Training Videos</a> and <a href="#faq"> Frequently Asked Questions (FAQs)</a> for Queue, as well as links to the <a target="_blank" href="/assets/hearingprep_trainingguide-700f99a0935b6f978096a0a13e593fa5ccfdc60f0c1b106f0c1a44672065f474.pdf">Training Guide</a> and the  <a target="_blank" rel="noopener noreferrer" href="/assets/hearingprep_quickreference-ab220e981c81dbd346c0e83631ada13474051d2355ab193bcbcfbddd14432aca.pdf">Quick Reference</a>. These items are provided to assist you as you access and Queue. If you require further assistance after reviewing these items, please contact the Caseflow Product Support Team by phone (1-844-876-5548) or email <a href="mailto:caseflow@va.gov">(caseflow@va.gov)</a>. We look forward to assisting you.
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

      <div className="cf-help-divider"></div>
      <h2 id="what-is-caseflow-queue">1. What is Caseflow Queue?</h2>

      <p>Caseflow Hearing Prep helps judges rapidly prepare for their hearings. It allows judges to view their upcoming hearings, view relevant appellant information, take notes before and during a hearing, and review documents in the veteran's eFolder. Hearing Prep was built by the Digital Service at VA (DSVA) and will create cost savings and process improvements for many areas at the VA. Learn more:
        <a target="_blank" rel="noopener noreferrer" href="/assets/hearingprep_trainingguide-700f99a0935b6f978096a0a13e593fa5ccfdc60f0c1b106f0c1a44672065f474.pdf">Training Guide</a>
      </p>

      <h2 id="how-was-queue-developed">2. How was Queue developed?</h2>

      <p>The Digital Service at VA (DSVA) team worked closely with judges at BVA and other stakeholders across VA, to develop and test a Hearing Prep prototype. Using feedback from VA employees and human-centered design principles, DSVA has tweaked and improved the tool steadily, and will continue improving the tool as they collect more feedback from its users.
      </p>

      <h2 id="launch-queue">3. How do I launch Queue?</h2>

      <p>To gain access to Hearing Prep, you must submit a request to your Information Security Officer (ISO) and/or Information Resources Management (IRM) team to adjust your Common Security Employee Manager (CSEM) permissions. To initiate the request, draft an email requesting your current permissions be updated as follows:
      </p>

      <p className="cf-help-image-wrapper">
        <img className="cf-help-image" alt="Hearing Access" src="/assets/help/hearing-access-aed4b8cb3441957305a4d61040ddf0d148339f6109f6ea11e1bd5181e841eea5.png" />
      </p>

      <h2 id="queue-get-cases">4. Where does Queue get cases?</h2>

      <p>To launch Hearing Prep, open Google Chrome and paste the following URL into the browser: <a href="https://appeals.cf.ds.va.gov/hearings/dockets" target="_blank" rel="noopener noreferrer"> https://appeals.cf.ds.va.gov/hearings/dockets</a>. Hit Enter and sign in using your VA credentials. You will be taken to the Hearing Prep Upcoming Hearing Days page.
      </p>

      <h2 id="veteran-data">5. Where does the Veteran and appeal data in Queue come from?</h2>

      <p>To view your hearing docket for a specific day, on the Upcoming Hearing Days page, click on the date that you would like to view. You will be taken to the Daily Docket for that specific date and will be able to view all the hearings scheduled for that day.
      </p>

      <h2 id="cases-not-assigned-to-me">6. How can I see cases that are not assigned to me?</h2>

      <p>You can search for cases that are not assigned to you by entering a Veteran ID in the search bar in
        the top left of the screen. The Hearing Worksheet can be accessed by clicking on the Veteran’s VBMS ID located below the name of the Appellant. On the Hearing Worksheet, you will be able to view Appellant/Veteran Profile Information, Appeal Stream Documents and Issues, Contentions, Periods and circumstances of service, Evidence, and your Comments and special instructions to attorneys.
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

    </div>;
    /* eslint-disable max-len */
  }
}

export default QueueHelp;
