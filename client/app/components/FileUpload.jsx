import React from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

const styling = css({
  display: 'none'
});

export default class FileUpload extends React.Component {
  render() {
    return <div>
      <label htmlFor={this.props.id}>
        <Link
          onChange={this.props.onChange}
        >
          {this.props.text}
        </Link>
      </label>
      <div {...styling}>
        <input
          type="file"
          id={this.props.id}
        />
      </div>
    </div>
  }
}

FileUpload.propTypes = {
  onChange: PropTypes.func,
  id: PropTypes.string,
  text: PropTypes.string
};
