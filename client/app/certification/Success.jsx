import React from 'react';
import { connect } from 'react-redux';
import StatusMessage from '../components/StatusMessage';


export class Success extends React.Component {
  render() {
    let {
      veteranName,
      poaCorrectLocation
    } = this.props;

    const checklist = [
      'Verified documents were in eFolder',
      'Completed and uploaded Form 8',
      'Hearing fields updated in VACOLS'];

    const updatedRepInVacols = ['Representative fields updated in VACOLS'];

    const message = `${veteranName}'s case has been certified.
     You can now close this window and open another
      appeal in VACOLS.`;

    window.scrollTo(0, 0);

    return <StatusMessage
      title="Success!"
      leadMessageList={[message]}
      checklist={poaCorrectLocation === 'VACOLS' ? checklist : checklist.concat(updatedRepInVacols)}
      type="success"
    />;
  }
}

const mapStateToProps = (state) => ({
  veteranName: state.veteranName,
  poaCorrectLocation: state.poaCorrectLocation
});

export default connect(
  mapStateToProps
)(Success);
