import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { onFileTypeChange } from '../actions';
import BuildScheduleUpload from '../components/BuildScheduleUpload';

export class BuildScheduleUploadContainer extends React.Component {
  render() {
    return <BuildScheduleUpload
      fileType={this.props.fileType}
      onFileTypeChange={this.props.onFileTypeChange}
    />;
  }
}

const mapStateToProps = (state) => ({
  fileType: state.fileType
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onFileTypeChange
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(BuildScheduleUploadContainer);
