import React from 'react';
import { connect } from 'react-redux';
import { ClipboardIcon } from '../components/RenderFunctions';
import { css } from 'glamor';

export class Header extends React.Component {
  render() {
    let {
      veteranName,
      vbmsId,
      serverError
    } = this.props;

    const copyIcon = css({ display: 'inline-block',
      marginLeft: '.25rem',
      verticalAlign: '-1px'
    });

    return <div>
      { !serverError && <div id="certifications-header" className="cf-app-segment">
        <div className="cf-txt-uc cf-veteran-name-control cf-push-left">
          {veteranName} &nbsp;
        </div>

        <div className="cf-txt-uc cf-apppeal-id-control cf-push-right">
          Veteran ID &nbsp;

          <button type="submit"
            title="Copy to clipboard"
            className="cf-apppeal-id"
            data-clipboard-text={vbmsId}>
            {vbmsId}
            <ClipboardIcon className="cf-icon-appeal-id" {...copyIcon} />
          </button>
        </div>
      </div>}
      <div className="cf-help-divider"></div>
    </div>;
  }
}

const mapStateToProps = (state) => ({
  veteranName: state.veteranName,
  vbmsId: state.vbmsId,
  serverError: state.serverError
});

export default connect(
  mapStateToProps
)(Header);

