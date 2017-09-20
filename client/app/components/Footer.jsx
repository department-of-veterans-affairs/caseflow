import React from 'react';
import PropTypes from 'prop-types';
import Link from './Link';

export default class Footer extends React.Component {

  onClick = (title) => () => {
    window.analyticsEvent('menu', title.toLowerCase(), 'feedback');
  }

  render() {
    const {
      appName,
      buildDate,
      feedbackUrl
    } = this.props;

    const analyticsTitle = `${appName} Feedback`;

    return <footer className="cf-app-footer">
      <div className="cf-app-width">
        <div className="cf-push-left">
          <span title={buildDate}>Built</span> with <abbr title="love">&#9825;</abbr> by the
          <a href="https://www.usds.gov/"> Digital Service at the
            <abbr title="Department of Veterans Affairs"> VA</abbr>
          </a>
        </div>
        <div className="cf-push-right">
          <Link
            href={feedbackUrl}
            target="_blank"
            onClick={this.onClick(analyticsTitle)}>Send feedback</Link>
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
