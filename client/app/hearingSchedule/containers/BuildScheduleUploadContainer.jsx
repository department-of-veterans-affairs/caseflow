import React from 'react';
import BuildScheduleUpload from '../components/BuildScheduleUpload';

export class BuildScheduleUploadContainer extends React.Component {
  render() {
    return <BuildScheduleUpload
      fileType="RO/CO"
    />;
  }
}

export default BuildScheduleUploadContainer;
