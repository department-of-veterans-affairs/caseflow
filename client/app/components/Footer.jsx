import React from 'react';
import PropTypes from 'prop-types';
import Link from './Link';

export default class Footer extends React.Component {

  onFeedbackClick = (title) => {
    window.analyticsEvent(title, 'feedback', 'footer');
  }

  render() {
    const {
      appName,
      buildDate,
      feedbackUrl
    } = this.props;

    return <footer className="cf-app-footer">
      <div className="cf-app-width">
        <div className="cf-push-left">
          <span title={buildDate}>Built</span> with <abbr title="love">&#9825;</abbr> by the
          <Link href="https://www.usds.gov"> Digital Service at the
            <abbr title="Department of Veterans Affairs"> VA</abbr></Link>
        </div>
        <div className="cf-push-right">
          <Link
            href={feedbackUrl}
            target="_blank"
            onClick={this.onFeedbackClick(appName)}>Send feedback</Link>
        </div>
      </div>
    </footer>;
  }
}

Footer.propTypes = {
  appName: PropTypes.string.isRequired,
  buildDate: PropTypes.string,
  feedbackUrl: PropTypes.string.isRequired
};
