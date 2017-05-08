import React from 'react';
import { connect } from 'react-redux';
import StatusMessage from '../components/StatusMessage';

const UnconnectedSuccess = ({
  veteranName,
  vbmsId
}) => {
<<<<<<< HEAD
  return <div id="certifications-generate"
    className="cf-app-msg-screen cf-app-segment cf-app-segment--alt">
    <h1 className="cf-success cf-msg-screen-heading">
      Success!
    </h1>
    <h2 className="cf-msg-screen-deck">
      {veteranName}'s case {vbmsId} has been certified. 
      You can now close this window and open another appeal in VACOLS.
    </h2>
=======
  const checklist = [
    'Verified documents were in eFolder',
    'Completed and uploaded Form 8',
    'Representative and hearing fields updated in VACOLS'];
  const message = `${veteranName}'s case ${vbmsId} has been certified. 
  You can now close this window and open another appeal in VACOLS.`;
>>>>>>> 3a377a3421773c41115a9d26ffc42e2ed50d02d0


<<<<<<< HEAD

  </div>;
=======
  return <StatusMessage
    title="Congratulations!"
    leadMessageList={[message]}
    checklist={checklist}
    messageText="Way to go! You can now close this window and open another
    appeal in VACOLS."
    type="success"
    />;
>>>>>>> 3a377a3421773c41115a9d26ffc42e2ed50d02d0
};

const mapStateToProps = (state) => ({
  veteranName: state.veteranName,
  vbmsId: state.vbmsId
});

const Success = connect(
  mapStateToProps
)(UnconnectedSuccess);

export default Success;
