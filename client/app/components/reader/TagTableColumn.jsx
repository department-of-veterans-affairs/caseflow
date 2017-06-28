import React, { PureComponent } from 'react';
import PropTypes from 'prop-types';
import Highlighter from 'react-highlight-words';
import _ from 'lodash';

class TagTableColumn extends PureComponent {
  render() {
    const { tags, searchQuery } = this.props;

    return <div className="document-list-issue-tags">
      {tags && tags.map((tag) => {
        return <div className="document-list-issue-tag" 
            key={tag.id}>
            <Highlighter
               searchWords={_.union(searchQuery.split(' '), [searchQuery])}
              textToHighlight={tag.text}
            />
          </div>;
      })}
    </div>;
  }
}

TagTableColumn.propTypes = {
  tags: PropTypes.arrayOf(PropTypes.object)
};

export default TagTableColumn;
