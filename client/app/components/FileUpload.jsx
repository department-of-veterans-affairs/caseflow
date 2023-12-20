import React from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

const styling = css({
  display: 'none'
});

export default class FileUpload extends React.Component {

  onUploadEvent = (event) => {
    const reader = new FileReader();
    const file = event.target.files[0];

    reader.onloadend = () => this.props.onChange({
      file: reader.result,
      fileName: file.name
    });
    reader.readAsDataURL(file);
  };

  render() {
    return <div>
      <label htmlFor={this.props.id}>
        {this.props.value && <b>{this.props.value.fileName}&nbsp;</b>}
        <Link
          onChange={this.props.onChange}
        >
          {this.props.value ? this.props.postUploadText : this.props.preUploadText}
        </Link>
      </label>
      <div {...styling}>
        <input
          type="file"
          accept={this.props.fileType}
          id={this.props.id}
          onChange={this.onUploadEvent}
        />
      </div>
    </div>;
  }
}

FileUpload.propTypes = {
  onChange: PropTypes.func.isRequired,
  id: PropTypes.string.isRequired,
  preUploadText: PropTypes.string.isRequired,
  postUploadText: PropTypes.string.isRequired,
  fileType: PropTypes.string,
  value: PropTypes.object
};
