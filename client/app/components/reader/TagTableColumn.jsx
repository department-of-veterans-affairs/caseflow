import React, { PureComponent } from 'react';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import Highlight from '../Highlight';

class TagTableColumn extends PureComponent {
  render() {
    const { tags, searchQuery } = this.props;

    return <div className="document-list-issue-tags">
      {tags && tags.map((tag) => {
        return <div className="document-list-issue-tag"
            key={tag.id}>
            <Highlight
              searchQuery={searchQuery}
              textToHighlight={tag.text}
            />
          </div>;
      })}
    </div>;
  }
}

const mapStateToProps = (state) => ({
  searchQuery: state.ui.docFilterCriteria.searchQuery
});

TagTableColumn.propTypes = {
  tags: PropTypes.arrayOf(PropTypes.object),
  searchQuery: PropTypes.string
};

export default connect(mapStateToProps)(TagTableColumn);
