import React from 'react';
import { connect } from 'react-redux';
import StatusMessage from '../components/StatusMessage';

const UnconnectedSuccess = ({
  veteranName,
  vbmsId
}) => {
  const checklist = [
    'Verified documents were in eFolder',
    'Completed and uploaded Form 8',
    'Representative and hearing fields updated in VACOLS'];
  const message = `${veteranName}'s case ${vbmsId} has been certified. You can now close this window and open another appeal in VACOLS.`;


  return <StatusMessage
    title="Congratulations!"
    leadMessageList={[message]}
    checklist={checklist}
    messageText="Way to go! You can now close this window and open another
    appeal in VACOLS."
    type="success"
    />;
};

const mapStateToProps = (state) => ({
  veteranName: state.veteranName,
  vbmsId: state.vbmsId
});

const Success = connect(
  mapStateToProps
)(UnconnectedSuccess);

export default Success;
