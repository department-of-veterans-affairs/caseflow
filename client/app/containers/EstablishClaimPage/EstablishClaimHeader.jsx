import React from 'react';
import { ClipboardIcon } from '../../components/RenderFunctions';
import CopyToClipboard from 'react-copy-to-clipboard';
import { css } from 'glamor';

class EstablishClaimHeader extends React.Component {
  render() {
    const headerContainer = css({
      marginTop: '15px'
    });
    const headerdivider = css({
      clear: 'left',
      paddingTop: '10px'
    });

    return <section {...headerContainer}>
      <div className="cf-txt-uc cf-veteran-name-control cf-push-left">
          First Name, Last Name &nbsp;
      </div>
      <div className="cf-txt-uc cf-apppeal-id-control cf-push-right">
          Veteran ID &nbsp;

        <CopyToClipboard text="9999">
          <button
            name="Copy Veteran ID"
            className={['cf-copy-to-clipboard cf-apppeal-id']}>
                 99999
            <ClipboardIcon />
          </button>
        </CopyToClipboard>

      </div>

      <div className="cf-help-divider" {...headerdivider}></div>
    </section>;
  }
}

export default EstablishClaimHeader;

