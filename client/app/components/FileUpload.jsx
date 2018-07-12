import React from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import ApiUtil from '../util/ApiUtil';

const styling = css({
  display: 'none'
});

export default class FileUpload extends React.Component {

  onSuccess = (value) => () => {
    this.props.onChange(value)
  };

  onUploadEvent = (event) => {
    ApiUtil.uploadFile(
      event.target.files[0],
      this.props.postFilePath,
      this.onSuccess(event.target.files[0].name)
    );
  };

  render() {
    return <div>
      <label htmlFor={this.props.id}>
        {this.props.value && <b>{this.props.value}&nbsp;</b>}
        <Link
          onChange={this.props.onChange}
        >
          {this.props.value ? this.props.postUploadText : this.props.preUploadText}
        </Link>
      </label>
      <div {...styling}>
        <input
          type="file"
          id={this.props.id}
          onChange={this.onUploadEvent}
        />
      </div>
    </div>;
  }
}

FileUpload.propTypes = {
  onChange: PropTypes.func.isRequired,
  postFilePath: PropTypes.string,
  id: PropTypes.string.isRequired,
  preUploadText: PropTypes.string.isRequired,
  postUploadText: PropTypes.string.isRequired,
  value: PropTypes.string
};
