import React from 'react';

export default class TagTableColumn extends React.Component {
  render() {
    const {
      doc
    } = this.props;
    const tags = doc.tags;

    return <div className="document-list-issue-tags">
      {tags && tags.map((tag) => {
        return <div className="document-list-issue-tag">
            {`${tag.text}`}
          </div>;
      })}
    </div>;
  }
}
