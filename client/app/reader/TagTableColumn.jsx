import React, { PureComponent } from 'react';
import PropTypes from 'prop-types';
import Highlight from '../components/Highlight';

class TagTableColumn extends PureComponent {
  render() {
    const { tags } = this.props;

    return <div className="document-list-issue-tags">
      {tags && tags.map((tag) => {
        return <div className="document-list-issue-tag"
          key={tag.id}>
          <Highlight>
            {tag.text}
          </Highlight>
        </div>;
      })}
    </div>;
  }
}

TagTableColumn.propTypes = {
  tags: PropTypes.arrayOf(PropTypes.object)
};

export default TagTableColumn;
