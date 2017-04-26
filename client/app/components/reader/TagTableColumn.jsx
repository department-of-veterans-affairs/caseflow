import React from 'react';

const TagTableColumn = ({ doc }) => (
  <div className="document-list-issue-tags">
    {doc.tags && doc.tags.map((tag) => {
      return <div className="document-list-issue-tag">
          {tag.text}
        </div>;
    })}
  </div>
);

export default TagTableColumn;
