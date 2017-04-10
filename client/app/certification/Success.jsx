import React from 'react';
import { connect } from 'react-redux';

const UnconnectedSuccess = ({
  veteranName,
  vbmsId
}) => {
  return <div id="certifications-generate"
    className="cf-app-msg-screen cf-app-segment cf-app-segment--alt">
    <h1 className="cf-success cf-msg-screen-heading">
      Congratulations!
    </h1>
    <h2 className="cf-msg-screen-deck">
      {veteranName}'s case {vbmsId} has been certified.
    </h2>

    <ul className="cf-checklist">
        <li>
          <span className="cf-icon-success--bg"></span>
          Verified documents were in eFolder
        </li>
        <li>
          <span className="cf-icon-success--bg cf-success"></span>
          Completed and uploaded Form 8
        </li>
        <li>
          <span className="cf-icon-success--bg cf-success"></span>
          Representative and hearing fields were updated in VACOLS
        </li>
    </ul>

    <p className="cf-msg-screen-text">
      {`Way to go! You can now close this window
        and open another appeal in VACOLS.`}
    </p>
  </div>;
};

const mapStateToProps = (state) => {
  return {
    veteranName: state.veteranName,
    vbmsId: state.vbmsId
  };
};

const Success = connect(
  mapStateToProps
)(UnconnectedSuccess);

export default Success;
