import React from 'react';
import StatusMessage from '../components/StatusMessage';
import StringUtil from '../util/StringUtil';
import { detect } from 'detect-browser';
import { css } from 'glamor';
import PropTypes from 'prop-types';

export default class UnsupportedBrowserBanner extends React.PureComponent {
  render() {
    const browser = detect();

    const title = `${browser.name === 'ie' ?
      'Internet Explorer' : StringUtil.snakeCaseToCapitalized(browser.name)} is not supported`;

    const errorTitle = `${browser.name !== 'chrome' && title}`;

    const linkStyling = css({ textDecoration: 'underline' });

    const message = <span> To access {this.props.appName}, you must use Chrome as your browser.<br />
    If you need to install Chrome on your computer, please call the <br />
    VA Enterprise Service Desk at
      <a {...linkStyling} href="tel:855-673-4357"> 855-673-4357</a>.</span>;

    return <div>
      <StatusMessage
        title={errorTitle}
        leadMessageList={[message]} />
    </div>;
  }
}

UnsupportedBrowserBanner.propTypes = {
  appName: PropTypes.string.isRequired
};
