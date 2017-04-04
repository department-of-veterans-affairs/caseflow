import React from 'react';
import { connect } from 'react-redux';

const UnconnectedHeader = ({
  veteranName,
  vbmsId
}) => {
  return <div id="certifications-header" className="cf-app-segment">
    <div className="cf-txt-uc cf-apppeal-id-control cf-push-right">
      {veteranName} &nbsp;

      <button type="submit"
        title="Copy to clipboard"
        className="cf-apppeal-id"
        data-clipboard-text={vbmsId}>
        {vbmsId}
        {/*eslint-disable */}
       <svg width="16" height="16" className="cf-icon-appeal-id"
        xmlns="http://www.w3.org/2000/svg" viewBox="0 0 21 21">
        <title>appeal</title>
        <path d="M13.346 2.578h-2.664v-1.29C10.682.585 10.08 0 9.35 0H6.66c-.728 0-1.33.584-1.33
        1.29v1.288H2.663v2.577h10.682V2.578zm-4.02 0H6.66v-1.29h2.665v1.29zm6.685
        3.89V3.234a.665.665 0 0
        0-.678-.656H14v1.29h.68v2.576H6.66v9.046H1.333V3.867h.68v-1.29H.678a.665.665 0 0
        0-.68.657v12.913c0 .365.302.656.68.656h6.006v3.867h9.35l3.996-3.867V6.468h-4.02zm0
        12.378v-2.043h2.112l-2.11 2.043zm2.665-3.356H14.68v3.867H7.992v-11.6h10.682v7.733z"
        fill="#5B616B" fillRule="evenodd"/></svg>
        {/*eslint-enable */}
      </button>
    </div>
  </div>;
};

const mapStateToProps = (state) => {
  return {
    veteranName: state.veteranName,
    vbmsId: state.vbmsId
  };
};

const Header = connect(
  mapStateToProps
)(UnconnectedHeader);

export default Header;
