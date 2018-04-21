import React from 'react';
import PropTypes from 'prop-types';
import StatusMessage from '../../components/StatusMessage';
import StringUtil from '../../util/StringUtil';
import { detect } from 'detect-browser';

export default class UnsupportedBrowserBanner extends React.PureComponent {
  render() {
    const browser = detect();
    const title =`${browser.name === 'ie' ?
    'Internet Explorer' : StringUtil.snakeCaseToCapitalized(browser.name)} is not supported`;

     return <div>
     <StatusMessage title={browser.name !=='chrome' ? title : ''}>
       To access Hearing Prep, you must use Chrome as your browser.<br />
       If you need to install Chrome on your computer, please call the <br/>
       VA Enterprise Service Desk at
        <a className="hearing-status-message" href="tel:855-673-4357"> 855-673-4357 </a>.
      </StatusMessage>
    </div>
  }
}
