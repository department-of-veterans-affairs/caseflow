import React, { PropTypes } from 'react';
import Button from '../components/Button';

export const LABELS = ['blue', 'orange', 'white', 'pink', 'green', 'yellow'];

export default class DocumentLabels extends React.Component {
  render() {
    let bookmarkClasses = ['cf-pdf-bookmarks', 'cf-pdf-button', 'cf-label'];
    let bookmarkClassesSelected = [...bookmarkClasses, 'cf-selected-label'];

    let bookmarks = LABELS.map((label) => {
      let className = `fa fa-bookmark cf-pdf-bookmark-${label}`;
      return <Button
        key={label}
        name={label}
        classNames={this.props.selectedLabels[label] ? bookmarkClassesSelected : bookmarkClasses}
        onClick={this.props.onClick(label)}>
        <i
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
  onClick: PropTypes.func.isRequired,
  selectedLabels: PropTypes.object
};
