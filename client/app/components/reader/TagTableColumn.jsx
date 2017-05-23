import React, { PureComponent } from 'react';
import PropTypes from 'prop-types';

class TagTableColumn extends PureComponent {
  render() {
    const { doc } = this.props;

    return <div className="document-list-issue-tags">
      {doc.tags && doc.tags.map((tag) => {
        return <div className="document-list-issue-tag" key={tag.id}>
            {tag.text}
          </div>;
      })}
    </div>;
  }
}

TagTableColumn.propTypes = {
  doc: PropTypes.object.isRequired
};

export default TagTableColumn;
