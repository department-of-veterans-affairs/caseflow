// External Dependencies
import React from 'react';
import PropTypes from 'prop-types';
import { sortBy as sort } from 'lodash';

// Local Dependencies
import { formatDateStr } from 'app/util/DateUtil';
import Button from 'app/components/Button';
import DropdownFilter from 'app/components/DropdownFilter';
import ViewableItemLink from 'app/components/ViewableItemLink';
import Highlight from 'app/components/Highlight';
import FilterIcon from 'app/components/FilterIcon';
import { DoubleArrow } from 'app/components/RenderFunctions';

import Comment from 'app/reader/Comment';
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
export const commentValue = (annotations, jumpToComment) => (doc) => (
  <ul className="cf-no-styling-list" aria-label="Document comments">
    {sort(annotations[doc.id], ['page', 'y']).map((comment, index) => (
      <Comment
        key={comment.uuid}
        id={`comment${doc.id}-${index}`}
        selected={false}
        page={comment.page}
        onJumpToComment={jumpToComment(comment)}
        uuid={comment.uuid}
        date={comment.relevant_date}
        horizontalLayout
      >
        {comment.comment}
      </Comment>
    ))}
  </ul>
);

/**
 * Category Header Component
 * @param {Object} props -- Contains the category filters and functions to apply/remove them
 */
export const CategoryHeader = ({
  pdfList,
  docFilterCriteria,
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
      selected={pdfList?.dropdowns?.category || docFilterCriteria?.category}
      handleActivate={toggleFilter}
    />
    {pdfList?.dropdowns?.category && (
      <DropdownFilter
        clearFilters={clearCategoryFilters}
        name="category"
        isClearEnabled={docFilterCriteria?.category}
        handleClose={toggleFilter}
        addClearFiltersRow
      >
        <CategoryPicker
          {...props}
          categoryToggleStates={docFilterCriteria?.category}
          handleCategoryToggle={setCategoryFilter}
        />
      </DropdownFilter>
    )}
  </div>
);

CategoryHeader.propTypes = {
  pdfList: PropTypes.object,
  docFilterCriteria: PropTypes.object,
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
    ariaLabel={`Sort by Receipt Date. ${sortBy === 'receivedAt' ? sortLabel : '' }`}
    onClick={() => changeSort('receivedAt')}
  >
    Receipt Date {sortBy === 'receivedAt' ? sortIcon : <DoubleArrow />}
  </Button>
);

ReceiptDateHeader.propTypes = {
  sortBy: PropTypes.string,
  sortIcon: PropTypes.element,
  changeSort: PropTypes.func,
  sortLabel: PropTypes.string,
};

/**
 * Receipt Date Value for Receipt Date Column in Documents table
 * @param {Object} doc -- The document for which to display the receipt date
 */
export const receiptDateValue = (doc) => (
  <span className="document-list-receipt-date">
    <Highlight>
      {formatDateStr(doc.receivedAt)}
    </Highlight>
  </span>
);

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
export const typeValue = ({ doc, setPdf, documentPathBase }) => (
  <div>
    <ViewableItemLink
      boldCondition={!doc.opened_by_current_user}
      onOpen={(id) => setPdf(id)}
      linkProps={{
        to: `${documentPathBase}/${doc.id}`,
        'aria-label': doc.type + (doc.opened_by_current_user ? ' opened' : ' unopened')
      }}
    >
      <Highlight>
        {doc.type}
      </Highlight>
    </ViewableItemLink>
    {doc.description && (
      <p className="document-list-doc-description">
        <Highlight>{doc.description}</Highlight>
      </p>
    )}
  </div>
);

typeValue.propTypes = {
  doc: PropTypes.object,
  documentPathBase: PropTypes.string,
  setPdf: PropTypes.func
};

/**
 * Tags Header Component
 * @param {Object} props -- Contains the tag filters and functions to apply/remove them
 */
export const TagHeader = ({
  pdfList,
  docFilterCriteria,
  tagFilterRef,
  toggleFilter,
  clearTagFilters,
  setTagFilter,
  pdfViewer,
  ...props
}) => (
  <div id="tags-header" className="document-list-header-issue-tags">
    Issue Tags
    <FilterIcon
      label="Filter by tag"
      idPrefix="tag"
      getRef={tagFilterRef}
      selected={pdfList?.dropdowns?.tag || docFilterCriteria?.tag}
      handleActivate={toggleFilter}
    />
    {pdfList?.dropdowns?.tag && (
      <DropdownFilter
        clearFilters={clearTagFilters}
        name="tag"
        isClearEnabled={docFilterCriteria?.tag}
        handleClose={toggleFilter}
        addClearFiltersRow
      >
        <TagPicker
          {...props}
          tags={pdfViewer.tagOptions}
          tagToggleStates={docFilterCriteria?.tag}
          handleTagToggle={setTagFilter}
        />
      </DropdownFilter>
    )}
  </div>
);

TagHeader.propTypes = {
  pdfList: PropTypes.object,
  docFilterCriteria: PropTypes.object,
  pdfViewer: PropTypes.object,
  tagFilterRef: PropTypes.element,
  toggleFilter: PropTypes.func,
  clearTagFilters: PropTypes.func,
  setTagFilter: PropTypes.func
};

/**
 * Document Tag Column component
 * @param {Object} props -- Contains the document tags
 */
export const tagValue = ({ tags }) => (
  <div className="document-list-issue-tags">
    {tags && tags.map((tag) =>
      <div className="document-list-issue-tag"
        key={tag.id}>
        <Highlight>
          {tag.text}
        </Highlight>
      </div>
    )}
  </div>
);

tagValue.propTypes = {
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
    valueFunction: (doc) => <LastReadIndicator docId={doc.id} getRef={lastReadIndicatorRef} />
  },
  {
    cellClass: 'categories-column',
    header: <CategoryHeader {...props} />,
    valueFunction: (doc) => <CategoryIcons doc={doc} {...props} />
  },
  {
    cellClass: 'receipt-date-column',
    header: <ReceiptDateHeader {...props} />,
    valueFunction: receiptDateValue
  },
  {
    cellClass: 'doc-type-column',
    header: <TypeHeader {...props} />,
    valueFunction: typeValue
  },
  {
    cellClass: 'tags-column',
    header: <TagHeader {...props} />,
    valueFunction: tagValue
  },
  {
    cellClass: 'comments-column',
    header: <CommentHeader {...props} />,
    valueFunction: (doc) => <CommentIndicator docId={doc.id} {...props} />
  }
];

/**
 * Comment Headers for the Documents Table
 * @param {Object} props -- Props contain annotations and jump to comment function
 */
export const commentHeaders = (props) => [
  {
    valueFunction: commentValue(props.annotationsPerDocument, props.jumpToComment),
    span: documentHeaders(props).length
  }
];
