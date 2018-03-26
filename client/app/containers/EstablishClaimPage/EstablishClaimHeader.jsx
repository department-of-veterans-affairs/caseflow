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
    let hasAppeal = this.props.task.appeal;

    return <section {...headerContainer}>
      <div className="cf-txt-uc cf-veteran-name-control cf-push-left">
        {hasAppeal.veteran_name} &nbsp;
      </div>
      <div className="cf-txt-uc cf-apppeal-id-control cf-push-right">
          Veteran ID &nbsp;

        <CopyToClipboard text={hasAppeal.vbms_id}>
          <button
            name="Copy Veteran ID"
            className={['cf-copy-to-clipboard cf-apppeal-id']}>
            {hasAppeal.vbms_id}
            <ClipboardIcon />
          </button>
        </CopyToClipboard>

      </div>

      <div className="cf-help-divider" {...headerdivider}></div>

    </section>;
  }
}

export default EstablishClaimHeader;

