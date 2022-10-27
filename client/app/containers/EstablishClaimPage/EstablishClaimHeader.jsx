import React from 'react';
import PropTypes from 'prop-types';
import { ClipboardIcon } from '../../components/icons/ClipboardIcon';
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

    return <section {...headerContainer}>
      <React.Fragment> <div className="cf-veteran-name-control cf-push-left">
        {this.props.appeal.veteran_name} &nbsp;
      </div>
      <div className="cf-push-right">
          Veteran ID &nbsp;
        <CopyToClipboard text={this.props.appeal.vbms_id}>
          <button {...clipboardButton}
            name="Copy Veteran ID"
            className={['cf-copy-to-clipboard cf-apppeal-id']}>
            {this.props.appeal.vbms_id}
            <ClipboardIcon />
          </button>
        </CopyToClipboard>
      </div>

      <div className="cf-help-divider" {...headerdivider}></div>
      </React.Fragment>
    </section>;
  }
}

EstablishClaimHeader.propTypes = {
  appeal: PropTypes.object.isRequired
};

export default EstablishClaimHeader;
