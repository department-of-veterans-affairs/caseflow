import React from 'react';
import { ClipboardIcon } from '../../components/RenderFunctions';
import CopyToClipboard from 'react-copy-to-clipboard';
import { css } from 'glamor';

class EstablishClaimHeader extends React.Component {

  render() {

    const headerContainer = css({
      marginTop: '16px'
    });
    const headerdivider = css({
      clear: 'left',
      paddingTop: '30px'
    });
    const clipboardButton = css({
      marginTop: '4px'
    });

    let hasAppeal = this.props.task;

    return <section {...headerContainer}>
      { hasAppeal && <React.Fragment> <div className="cf-txt-uc cf-veteran-name-control cf-push-left">
        {hasAppeal.appeal.veteran_name} &nbsp;
      </div>

      <div className="cf-txt-uc cf-apppeal-id-control cf-push-right">
          Veteran ID &nbsp;

        <CopyToClipboard text={hasAppeal.appeal.vbms_id}>
          <button {...clipboardButton}
            name="Copy Veteran ID"
            className={['cf-copy-to-clipboard cf-apppeal-id']}>
            {hasAppeal.appeal.vbms_id}
            <ClipboardIcon />
          </button>
        </CopyToClipboard>

      </div>

      <div className="cf-help-divider" {...headerdivider}></div>
      </React.Fragment>
      }
    </section>;
  }
}

export default EstablishClaimHeader;

