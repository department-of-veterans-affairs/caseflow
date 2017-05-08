import React from 'react';
import StyleGuideComponentTitle from '../../components/StyleGuideComponentTitle';
import StyleGuideAction from './StyleGuideAction';
import Button from '../../components/Button';




let StyleGuideFooter = () => {
  return <div>
      <StyleGuideComponentTitle
        title="Footer"
        id="footer"
        link="StyleGuideFooter.jsx"
        isSubsection={true}
    />
    <p>
     All of Caseflow Apps feature a minimal footer that contains the text
    “Built with ♡ by the Digital Service at the VA.” and a “Send Feedback” link.</p>
    <p>
     Conveniently, if a developer hover’s over the word
    “Built” they’ll see a tooltip showing the build date 
    of the app that they are viewing.</p>
    <div className="cf-app-segment cf-app-segment--alt"></div>
    <div className="cf-app-segment" id="establish-claim-buttons">
      <div className="cf-push-left">
        <Button
          name="View Work History"
          classNames={['cf-btn-link']}
        />
      </div>
      <div className="cf-push-right">
        <Button
          name="Cancel"
          classNames={['cf-btn-link', 'cf-adjacent-buttons']}
        />
        <Button
          name="Establish Next Claim"
          classNames={['usa-button-primary']}
        />
        </div>
    </div>

     <footer className="cf-txt-c usa-grid cf-app-footer">
      <div>
        <div className="cf-push-left">
          <span>Built</span> with <abbr title="love">♡</abbr> by the
          <a href="https://www.usds.gov/">Digital Service at the <abbr title="Department of Veterans Affairs">VA</abbr></a>
        </div>
        <div className="cf-push-right">
          <a target="_blank" href="https://dsva-appeals-feedback-demo-1748368704.us-gov-west-1.elb.amazonaws.com/?redirect=http%3A%2F%2Flocalhost%3A3000%2F&amp;subject=Caseflow" onclick="ga('send', 'event', { eventCategory: 'Menu', eventAction: 'ClickFeedback', eventLabel: 'Feedback', eventValue: 1});">
            Send feedback
          </a>
        </div>
      </div>
    </footer>
  </div>;
};
export default StyleGuideFooter;