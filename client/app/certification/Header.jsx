import React from 'react';
import { connect } from 'react-redux';
import { ClipboardIcon } from '../components/icons/ClipboardIcon';
import CopyToClipboard from 'react-copy-to-clipboard';
import PropTypes from 'prop-types';

export class Header extends React.Component {
  render() {
    let {
      veteranName,
      vbmsId,
      serverError
    } = this.props;

    return <div>
      { !serverError && <div id="certifications-header" className="cf-app-segment">
        <div className="cf-veteran-name-control cf-push-left">
          {veteranName} &nbsp;
        </div>

        <div className="cf-push-right">
          Veteran ID &nbsp;
          <CopyToClipboard text={vbmsId}>
            <button type="submit"
              title="Copy Veteran ID"
              className="cf-apppeal-id">
              {vbmsId}
              <ClipboardIcon />
            </button>
          </CopyToClipboard>
        </div>
      </div>}
      <div className="cf-help-divider"></div>
    </div>;
  }
}

Header.propTypes = {
  veteranName: PropTypes.string,
  vbmsId: PropTypes.number,
  serverError: PropTypes.string
};

const mapStateToProps = (state) => ({
  veteranName: state.veteranName,
  vbmsId: state.vbmsId,
  serverError: state.serverError
});

export default connect(
  mapStateToProps
)(Header);

