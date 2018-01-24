import React from 'react';

class CertificationHelp extends React.Component  {

  render() {
  	return <div className="cf-help-content">
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
		    <li><a href="#cannot-find-documents">5. Why does Caseflow say it cannot find documents in the appellant’s
		      eFolder?</a></li>
		    <li><a href="#mismatched-documents">6. What are the reasons Caseflow may not be
		      able to find documents in VBMS?</a></li>
		    <li><a href="#multiple-document-types">7. What should I do if an eFolder document contains multiple
		      types of information?</a></li>
		    <li><a href="#electronic-form8">8. How do I fill out an electronic Form 8?</a></li>
		    <li><a href="#preview-form8">9. What is the Preview Form 8 page?</a></li>
		    <li><a href="#upload-and-certify">10. What happens when I click the&nbsp;Upload and Certify&nbsp;button?</a></li>
		    <li><a href="#encounter-problem">11. What if I encounter a problem that prevents me from
		      certifying the appeal?</a></li>
		    <li><a href="#need-help">12. What do I do if I need help?</a></li>
		    <li><a href="#paper-appeals">13. How do I certify paper appeals?</a></li>
		    <li><a href="#virtual-va">14. What if my appeal has the Form 9, NOD, SOC, and/or SSOC in Virtual VA?</a></li>
		    <li><a href="#no-va646">15. What if my appeal does not have a completed VA-646 form?</a></li>
		    <li><a href="#notification-letters">16. How should I send out notification letters after I’ve certified
		      the appeal?</a></li>
		    <li><a href="#merged-appeals">17. Can I use Caseflow Certification with appeals that have been merged
		      together?</a></li>
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
    Once you're ready to certify an appeal, open and log in to VACOLS then search
    for the Appeal ID. Once the date for the Form 9, NOD, SOC, and any required
    SSOC have been entered into VACOLS, click the Certify Appeal button from the
    process menu. You can also select this option from the search results window or
    the update appeal window.
  </p>

  <p className="cf-help-image-wrapper">
    <img className="cf-help-image" alt="VACOLS Processes dialog" src="/assets/help/vacols-processes-e563d6a14dbc8adda7c0d328b4d411609c1199b79bdd849bf1bc742794e79775.png" />
  </p>
	  </div>
 }};

 export default CertificationHelp
