// External Dependencies
import React from 'react';
import PropTypes from 'prop-types';
import { sortBy as sort, isEmpty } from 'lodash';

// Local Dependencies
import { formatDateStr } from 'app/util/DateUtil';
import Button from 'app/components/Button';
import DropdownFilter from 'app/components/DropdownFilter';
import ViewableItemLink from 'app/components/ViewableItemLink';
import { Highlight } from 'components/reader/DocumentList/Highlight';
import FilterIcon from 'app/components/FilterIcon';
import { DoubleArrow } from 'app/components/RenderFunctions';

import { Comment } from 'components/reader/DocumentViewer/Sidebar/Comment';
import { CommentIndicator } from 'components/reader/DocumentList/DocumentsTable/CommentIndicator';
import { CategoryPicker } from 'components/reader/DocumentList/DocumentsTable/CategoryPicker';
import { CategoryIcons } from 'components/reader/DocumentList/DocumentsTable/CategoryIcons';
import { LastReadIndicator } from 'components/reader/DocumentList/DocumentsTable/LastReadIndicator';
import { TagPicker } from 'components/reader/DocumentList/DocumentsTable/TagPicker';

/**
 * Comment Column Value
 * @param {Object} annotations -- Object containing all annotations per document
 * @param {Function} jumpToComment -- Function to jump to the clicked comment
 */
export const commentValue = ({ comments, documentPathBase, ...props }) => (doc) => (
  <ul className="cf-no-styling-list" aria-label="Document comments">
    {sort(comments.filter((comment) => comment.document_id === doc.id), ['page', 'y']).map((comment, index) => (
      <Comment
        {...props}
        documentPathBase={documentPathBase}
        currentDocument={doc}
        comment={comment}
        key={comment.id}
        id={`comment${doc.id}-${index}`}
        selected={false}
        page={comment.page}
        date={comment.relevant_date}
        horizontalLayout
      />
    ))}
  </ul>
);

/**
 * Category Header Component
 * @param {Object} props -- Contains the category filters and functions to apply/remove them
 */
export const CategoryHeader = ({
  documentList,
  filterCriteria,
  catFilterRef,
  toggleFilter,
  clearCategoryFilters,
  setCategoryFilter,
  ...props
}) => (
  <div id="categories-header">
    Categories
    <FilterIcon
      label="Filter by category"
      idPrefix="category"
      getRef={catFilterRef}
      selected={documentList.pdfList?.dropdown?.category || filterCriteria?.category}
      handleActivate={() => toggleFilter('category')}
    />
    {documentList.pdfList?.dropdown?.category && (
      <DropdownFilter
        clearFilters={clearCategoryFilters}
        name="category"
        isClearEnabled={!isEmpty(filterCriteria?.category)}
        handleClose={() => toggleFilter('category')}
        addClearFiltersRow
      >
        <CategoryPicker
          {...props}
          categoryToggleStates={filterCriteria?.category}
          handleCategoryToggle={setCategoryFilter}
        />
      </DropdownFilter>
    )}
  </div>
);

CategoryHeader.propTypes = {
  documentList: PropTypes.object,
  filterCriteria: PropTypes.object,
  catFilterRef: PropTypes.element,
  toggleFilter: PropTypes.func,
  clearCategoryFilters: PropTypes.func,
  setCategoryFilter: PropTypes.func
};

/**
 * Receipt Date Header Component
 * @param {Object} props -- Contains the sort details and function to change
 */
export const ReceiptDateHeader = ({
  changeSort,
  sortBy,
  sortIcon,
  sortLabel
}) => (
  <Button
    name="Receipt Date"
    id="receipt-date-header"
    classNames={['cf-document-list-button-header']}
    ariaLabel={`Sort by Receipt Date. ${sortBy === 'received_at' ? sortLabel : '' }`}
    onClick={() => changeSort('received_at')}
  >
    Receipt Date {sortBy === 'received_at' ? sortIcon : <DoubleArrow />}
  </Button>
);

ReceiptDateHeader.propTypes = {
  sortBy: PropTypes.string,
  sortIcon: PropTypes.element,
  changeSort: PropTypes.func,
  sortLabel: PropTypes.string,
};

/* eslint-disable camelcase */
/**
 * Receipt Date Value for Receipt Date Column in Documents table
 * @param {Object} doc -- The document for which to display the receipt date
 */
export const ReceiptDateCell = ({ doc, filterCriteria }) => (
  <span className="document-list-receipt-date">
    <Highlight searchQuery={filterCriteria.searchQuery}>
      {formatDateStr(doc?.received_at)}
    </Highlight>
  </span>
);
/* eslint-enable camelcase */

ReceiptDateCell.propTypes = {
  filterCriteria: PropTypes.object,
  doc: PropTypes.object,
};

/**
 * Document Type Header Component
 * @param {Object} props -- Contains the sort details and function to change
 */
export const TypeHeader = ({
  changeSort,
  sortBy,
  sortIcon,
  sortLabel
}) => (
  <Button
    name="Document Type"
    id="type-header"
    classNames={['cf-document-list-button-header']}
    ariaLabel={`Sort by Document Type. ${sortBy === 'type' ? sortLabel : '' }`}
    onClick={() => changeSort('type')}
  >
    Document Type {sortBy === 'type' ? sortIcon : <DoubleArrow />}
  </Button>
);

TypeHeader.propTypes = {
  sortBy: PropTypes.string,
  sortIcon: PropTypes.element,
  changeSort: PropTypes.func,
  sortLabel: PropTypes.string,
};

/**
 * Document Type Column component
 * @param {Object} props -- Contains the document and functions to navigate
 */
export const TypeCell = ({ doc, documentPathBase, filterCriteria }) => (
  <div>
    <ViewableItemLink
      boldCondition={!doc.opened_by_current_user}
      linkProps={{
        to: `${documentPathBase}/${doc.id}`,
        'aria-label': doc.type + (doc.opened_by_current_user ? ' opened' : ' unopened')
      }}
    >
      <Highlight searchQuery={filterCriteria.searchQuery}>
        {doc.type}
      </Highlight>
    </ViewableItemLink>
    {doc.description && (
      <p className="document-list-doc-description">
        <Highlight searchQuery={filterCriteria.searchQuery}>{doc.description}</Highlight>
      </p>
    )}
  </div>
);

TypeCell.propTypes = {
  filterCriteria: PropTypes.object,
  doc: PropTypes.object,
  documentPathBase: PropTypes.string,
  showPdf: PropTypes.func
};

/**
 * Tags Header Component
 * @param {Object} props -- Contains the tag filters and functions to apply/remove them
 */
export const TagHeader = ({
  documentList,
  filterCriteria,
  tagFilterRef,
  toggleFilter,
  clearTagFilters,
  setTagFilter,
  ...props
}) => (
  <div id="tags-header" className="document-list-header-issue-tags">
    Issue Tags
    <FilterIcon
      label="Filter by tag"
      idPrefix="tag"
      getRef={tagFilterRef}
      selected={documentList.pdfList?.dropdown?.tag || filterCriteria?.tag}
      handleActivate={() => toggleFilter('tag')}
    />
    {documentList.pdfList?.dropdown?.tag && (
      <DropdownFilter
        clearFilters={clearTagFilters}
        name="tag"
        isClearEnabled={!isEmpty(filterCriteria?.tag)}
        handleClose={() => toggleFilter('tag')}
        addClearFiltersRow
      >
        <TagPicker
          {...props}
          tagToggleStates={filterCriteria?.tag}
          handleTagToggle={setTagFilter}
        />
      </DropdownFilter>
    )}
  </div>
);

TagHeader.propTypes = {
  documentList: PropTypes.object,
  filterCriteria: PropTypes.object,
  tagOptions: PropTypes.object,
  tagFilterRef: PropTypes.element,
  toggleFilter: PropTypes.func,
  clearTagFilters: PropTypes.func,
  setTagFilter: PropTypes.func
};

/**
 * Document Tag Column component
 * @param {Object} props -- Contains the document tags
 */
export const TagCell = ({ tags, filterCriteria }) => (
  <div className="document-list-issue-tags">
    {tags && tags.map((tag) =>
      <div className="document-list-issue-tag"
        key={tag.id}>
        <Highlight searchQuery={filterCriteria.searchQuery}>
          {tag.text}
        </Highlight>
      </div>
    )}
  </div>
);

TagCell.propTypes = {
  filterCriteria: PropTypes.object,
  tags: PropTypes.arrayOf(PropTypes.object)
};

/**
 * Comment Header for the Documents Table
 */
export const CommentHeader = () => (
  <div id="comments-header" className="document-list-header-comments">Comments</div>
);

/**
 * Comment Headers for the Documents Table
 * @param {Object} props -- Props contain annotations and jump to comment function
 */
export const documentHeaders = ({ lastReadIndicatorRef, ...props }) => [
  {
    cellClass: 'last-read-column',
    valueFunction: (doc) => <LastReadIndicator {...props} docId={doc.id} getRef={lastReadIndicatorRef} />
  },
  {
    cellClass: 'categories-column',
    header: <CategoryHeader {...props} />,
    valueFunction: (doc) => <CategoryIcons {...props} doc={doc} />
  },
  {
    cellClass: 'receipt-date-column',
    header: <ReceiptDateHeader {...props} />,
    valueFunction: (doc) => <ReceiptDateCell {...props} doc={doc} />
  },
  {
    cellClass: 'doc-type-column',
    header: <TypeHeader {...props} />,
    valueFunction: (doc) => <TypeCell {...props} doc={doc} />
  },
  {
    cellClass: 'tags-column',
    header: <TagHeader {...props} />,
    valueFunction: (doc) => <TagCell {...props} doc={doc} tags={doc.tags} />
  },
  {
    cellClass: 'comments-column',
    header: <CommentHeader {...props} />,
    valueFunction: (doc) => <CommentIndicator {...props} doc={doc} />
  }
];

/**
 * Comment Headers for the Documents Table
 * @param {Object} props -- Props contain annotations and jump to comment function
 */
export const commentHeaders = (props) => [
  {
    valueFunction: commentValue(props),
    span: () => documentHeaders(props).length
  }
];
