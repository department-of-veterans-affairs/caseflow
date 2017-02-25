import React, { PropTypes } from 'react';
import Button from '../components/Button';

export const LABEL_COLOR_MAPPING = {
  blue: {color: '#23ABF6'},
  orange: {color: '#F6A623'},
  white: {color: '#5B616B', outline: true},
  pink: {color: '#F772E7'},
  green: {color: '#3FCD65'},
  yellow: {color: '#EFDF1A'}
};

export default class DocumentLabels extends React.Component {
  render() {
    let bookmarkClasses = ['cf-pdf-bookmarks', 'cf-pdf-button', 'cf-label'];
    let bookmarkClassesSelected = [...bookmarkClasses, 'cf-selected-label'];

    let bookmarks = Object.keys(LABEL_COLOR_MAPPING).map((label) => {
      let className = 'fa fa-bookmark';
      if (LABEL_COLOR_MAPPING[label].outline) {
        className = 'fa fa-bookmark-o';
      }
      return <Button
        key={label}
        name={label}
        classNames={this.props.selectedLabels[label] ? bookmarkClassesSelected : bookmarkClasses}
        onClick={this.props.onClick(label)}>
        <i
          style={{ color: LABEL_COLOR_MAPPING[label].color }}
          className={className}
          aria-hidden="true"></i>
      </Button>
    });

    return <span>
      {bookmarks}
    </span>;
  }
}

DocumentLabels.propTypes = {
  onClick: PropTypes.func.isRequired
};
