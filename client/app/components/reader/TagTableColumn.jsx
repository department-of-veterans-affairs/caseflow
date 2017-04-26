import React from 'react';

const MAX_WIDTH = 225;

export default class TagTableColumn extends React.Component {
  render() {
    const {
      doc
    } = this.props;
    const tags = doc.tags;
    let tagsStyle = { maxWidth: MAX_WIDTH };

    return <div className="document-list-issue-tags" style={tagsStyle}>
      {tags && tags.map((tag) => {
        return <div className="document-list-issue-tag"
            style={tagsStyle}>
            {`${tag.text}`}
          </div>;
      })}
    </div>;
  }
}
