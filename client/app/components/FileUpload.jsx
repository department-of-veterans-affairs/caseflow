import React from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

const styling = css({
  display: 'none'
});

export default class FileUpload extends React.Component {

  onUploadEvent = (event) => {
    this.props.onChange(event.target.value);
  };

  render() {
    return <div>
      <label htmlFor={this.props.id}>
        {this.props.value && <b>{this.props.value.split('\\').slice(-1)[0]}&nbsp;</b>}
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
  onChange: PropTypes.func,
  id: PropTypes.string,
  preUploadText: PropTypes.string,
  postUploadText: PropTypes.string,
  value: PropTypes.string
};
