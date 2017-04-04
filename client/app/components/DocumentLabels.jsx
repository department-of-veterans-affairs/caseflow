import React, { PropTypes } from 'react';
import Button from '../components/Button';
import StringUtil from '../util/StringUtil';

const LABELS = [
  'decisions',
  'veteranSubmitted',
  'procedural',
  'vaMedial',
  'layperson',
  'privateMedical'
];

export default class DocumentLabels extends React.Component {
  onClick = (label) => () => {
    this.props.onClick(label);
  }

  render() {
    let bookmarkClasses = ['cf-pdf-bookmarks', 'cf-pdf-button', 'cf-label'];
    let bookmarkClassesSelected = [...bookmarkClasses, 'cf-selected-label'];

    let bookmarks = LABELS.map((label) => <Button
        key={label}
        name={label}
        classNames={this.props.selectedLabels[label] ?
          bookmarkClassesSelected : bookmarkClasses}
        onClick={this.onClick(label)}
        ariaLabel={`Filter by ${label} documents`}>
        <i
          className={`fa fa-bookmark cf-pdf-bookmark-` +
            `${StringUtil.camelCaseToDashCase(label)}`}
          aria-hidden="true"></i>
      </Button>);

    return <span>
      {bookmarks}
    </span>;
  }
}

DocumentLabels.propTypes = {
  onClick: PropTypes.func.isRequired,
  selectedLabels: PropTypes.object
};
