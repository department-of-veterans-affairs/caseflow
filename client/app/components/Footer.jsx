import React from 'react';

export default class Footer extends React.Component {
  render() {
    let {
      appName,
      analyticsTitle,
      buildDate,
      feedbackUrl
    } = this.props;

    return <footer className="cf-app-footer">
      <div className="cf-app-width">
        <div className="cf-push-left">
          <span title={buildDate}>Built</span> with <abbr title="love">&#9825;</abbr> by the
          <a href="https://www.usds.gov/"> Digital Service at the <abbr title="Department of Veterans Affairs">VA</abbr></a>
        </div>
        <div className="cf-push-right">
          <a target="_blank" href={feedbackUrl}>
            Send feedback
          </a>
        </div>
      </div>
    </footer>;
  }
}
