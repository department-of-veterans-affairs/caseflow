/* eslint-disable max-lines */
import React from 'react';
import PropTypes from 'prop-types';
import _ from 'lodash';
import { connect } from 'react-redux';

import { formatDateStr } from '../util/DateUtil';
import Comment from './Comment';
import DocumentCategoryIcons from './DocumentCategoryIcons';
import TagTableColumn from './TagTableColumn';
import Table from '../components/Table';
import Button from '../components/Button';
import CommentIndicator from './CommentIndicator';
import DropdownFilter from '../components/DropdownFilter';
import { bindActionCreators } from 'redux';
import Highlight from '../components/Highlight';
import {
  setDocListScrollPosition,
  changeSortState,
  clearTagFilters,
  clearCategoryFilters,
  setTagFilter,
  setCategoryFilter,
  toggleDropdownFilterVisibility,
  setDocFilter,
  clearDocFilters
} from '../reader/DocumentList/DocumentListActions';
import { getAnnotationsPerDocument } from './selectors';
import { SortArrowDownIcon } from '../components/icons/SortArrowDownIcon';
import { SortArrowUpIcon } from '../components/icons/SortArrowUpIcon';
import { DoubleArrowIcon } from '../components/icons/DoubleArrowIcon';

import DocCategoryPicker from './DocCategoryPicker';
import FilterIcon from '../components/icons/FilterIcon';
import LastReadIndicator from './LastReadIndicator';
import DocTypeColumn from './DocTypeColumn';
import DocTagPicker from './DocTagPicker';
import ReaderTableDropdownFilter from '../components/ReaderTableDropdownFilter';

const NUMBER_OF_COLUMNS = 6;

export const getRowObjects = (documents, annotationsPerDocument) => {
  return documents.reduce((acc, doc) => {
    acc.push(doc);
    const docHasComments = _.size(annotationsPerDocument[doc.id]);

    if (docHasComments && doc.listComments) {
      acc.push({
        ...doc,
        isComment: true,
      });
    }

    return acc;
  }, []);
};
class DocumentsTable extends React.Component {

  constructor(props) {
    super(props);
    this.state = {
      frozenDocs: ''
    };
  }

  componentDidMount() {
    if (this.state.frozenDocs === '') {
      const frozenDocs = this.props.documents;

      Object.freeze(frozenDocs);
      this.setState({
        frozenDocs
      });
    }
    if (this.props.pdfList.scrollTop) {
      this.tbodyElem.scrollTop = this.props.pdfList.scrollTop;

      if (this.lastReadIndicatorElem) {
        const lastReadBoundingRect = this.lastReadIndicatorElem.getBoundingClientRect();
        const tbodyBoundingRect = this.tbodyElem.getBoundingClientRect();
        const lastReadIndicatorIsInView =
          tbodyBoundingRect.top <= lastReadBoundingRect.top &&
          lastReadBoundingRect.bottom <= tbodyBoundingRect.bottom;

        if (!lastReadIndicatorIsInView) {
          const rowWithLastRead = _.find(this.tbodyElem.children, (tr) =>
            tr.querySelector(`#${this.lastReadIndicatorElem.id}`)
          );

          this.tbodyElem.scrollTop +=
            rowWithLastRead.getBoundingClientRect().top - tbodyBoundingRect.top;
        }
      }
    }
  }

  componentWillUnmount() {
    this.props.setDocListScrollPosition(this.tbodyElem.scrollTop);
  }

  getTbodyRef = (elem) => (this.tbodyElem = elem);
  getLastReadIndicatorRef = (elem) => (this.lastReadIndicatorElem = elem);
  getCategoryFilterIconRef = (categoryFilterIcon) =>
    (this.categoryFilterIcon = categoryFilterIcon);
  getTagFilterIconRef = (tagFilterIcon) => (this.tagFilterIcon = tagFilterIcon);
  getDocumentFilterIconRef = (documentFilterIcon) => (this.documentFilterIcon = documentFilterIcon);
  toggleCategoryDropdownFilterVisiblity = () =>
    this.props.toggleDropdownFilterVisibility('category');
  toggleTagDropdownFilterVisiblity = () =>
    this.props.toggleDropdownFilterVisibility('tag');

  toggleDocumentDropdownFilterVisiblity = () =>
    this.props.toggleDropdownFilterVisibility('document');

  getKeyForRow = (index, { isComment, id }) => {
    return isComment ? `${id}-comment` : id;
  };

  // eslint-disable-next-line max-statements
  getDocumentColumns = (row) => {
    const sortArrowIcon = this.props.docFilterCriteria.sort.sortAscending ? (
      <SortArrowUpIcon />
    ) : (
      <SortArrowDownIcon />
    );
    const notSortedIcon = <DoubleArrowIcon />;

    const anyFiltersSet = (filterType) =>
      Boolean(_.some(this.props.docFilterCriteria[filterType]));

    const anyCategoryFiltersAreSet = anyFiltersSet('category');
    const anyTagFiltersAreSet = anyFiltersSet('tag');
    const anyDocFiltersAreSet = anyFiltersSet('document');

    // We have blank headers for the comment indicator and label indicator columns.
    // We use onMouseUp instead of onClick for filename event handler since OnMouseUp
    // is triggered when a middle mouse button is clicked while onClick isn't.
    if (row && row.isComment) {
      return [
        {
          valueFunction: (doc) => {
            const comments = _.sortBy(
              this.props.annotationsPerDocument[doc.id],
              ['page', 'y']
            );
            const commentNodes = comments.map((comment, commentIndex) => {
              return (
                <Comment
                  key={comment.uuid}
                  id={`comment${doc.id}-${commentIndex}`}
                  selected={false}
                  page={comment.page}
                  onJumpToComment={this.props.onJumpToComment(comment)}
                  uuid={comment.uuid}
                  date={comment.relevant_date}
                  horizontalLayout
                >
                  {comment.comment}
                </Comment>
              );
            });

            return (
              <ul className="cf-no-styling-list" aria-label="Document comments">
                {commentNodes}
              </ul>
            );
          },
          span: _.constant(NUMBER_OF_COLUMNS),
        },
      ];
    }

    const populateDocumentFilter = () => {
      let docsArray = [];

      // looks through all document types, and only adds them into docsArray if they are unique
      this.state.frozenDocs.map((x) => docsArray.includes(x.type) ? true : docsArray.push(x.type));

      // convert each item to a hash for use in the document filter
      let filterItems = [];

      docsArray.forEach((x) => filterItems.push({
        value: docsArray.indexOf(x),
        text: x
      }));

      return filterItems;
    };

    const isCategoryDropdownFilterOpen = _.get(this.props.pdfList, [
      'dropdowns',
      'category',
    ]);
    const isTagDropdownFilterOpen = _.get(this.props.pdfList, [
      'dropdowns',
      'tag',
    ]);

    const isDocumentDropdownFilterOpen = _.get(this.props.pdfList, [
      'dropdowns',
      'document',
    ]);

    const sortDirectionAriaLabel = `${
      this.props.docFilterCriteria.sort.sortAscending ?
        'ascending' :
        'descending'
    }`;

    return [
      {
        cellClass: 'last-read-column',
        valueFunction: (doc) => (
          <LastReadIndicator
            docId={doc.id}
            getRef={this.getLastReadIndicatorRef}
          />
        ),
      },
      {
        cellClass: 'categories-column',
        ariaLabel: 'categories-header-label',
        header: (
          <div id="categories-header">
            <span id="categories-header-label">
              Categories{' '}
              {anyCategoryFiltersAreSet ? 'Filtering by Category' : ''}
            </span>
            <FilterIcon
              label="Filter by category"
              idPrefix="category"
              getRef={this.getCategoryFilterIconRef}
              selected={
                isCategoryDropdownFilterOpen || anyCategoryFiltersAreSet
              }
              handleActivate={this.toggleCategoryDropdownFilterVisiblity}
            />
            {isCategoryDropdownFilterOpen && (
              <DropdownFilter
                clearFilters={this.props.clearCategoryFilters}
                name="category"
                isClearEnabled={anyCategoryFiltersAreSet}
                handleClose={this.toggleCategoryDropdownFilterVisiblity}
                addClearFiltersRow
              >
                <DocCategoryPicker
                  categoryToggleStates={this.props.docFilterCriteria.category}

                  handleCategoryToggle={this.props.setCategoryFilter}
                />
              </DropdownFilter>
            )}
          </div>
        ),
        valueFunction: (doc) => <DocumentCategoryIcons doc={doc} />,
      },
      {
        cellClass: 'receipt-date-column',
        ariaLabel: 'receipt-date-header-label',
        sortProps: this.props.docFilterCriteria.sort.sortBy ===
          'receivedAt' && { 'aria-sort': sortDirectionAriaLabel },
        header: (
          <Button
            styling={{ 'aria-roledescription': 'sort button' }}
            name="Receipt Date"
            id="receipt-date-header"
            classNames={['cf-document-list-button-header']}
            onClick={() => this.props.changeSortState('receivedAt')}
          >
            <span id="receipt-date-header-label">Receipt Date</span>
            {this.props.docFilterCriteria.sort.sortBy === 'receivedAt' ?
              sortArrowIcon :
              notSortedIcon}
          </Button>
        ),
        valueFunction: (doc) => (
          <span className="document-list-receipt-date">
            <Highlight>{formatDateStr(doc.receivedAt)}</Highlight>
          </span>
        ),
      },
      {
        cellClass: 'doc-type-column',
        ariaLabel: 'type-header-label',
        sortProps: this.props.docFilterCriteria.sort.sortBy === 'type' && {
          'aria-sort': sortDirectionAriaLabel,
        },
        header: (
          <>
            <Button
              id="type-header"
              styling={{ 'aria-roledescription': 'sort button' }}
              name="Document Type"
              classNames={['cf-document-list-button-header']}
              onClick={() => this.props.changeSortState('type')}
            >
              <span id="type-header-label">Document Type</span>

              {this.props.docFilterCriteria.sort.sortBy === 'type' ?
                sortArrowIcon :
                notSortedIcon}
            </Button>
            <FilterIcon
              label="Filter by Document"
              idPrefix="document"
              getRef={this.getDocumentFilterIconRef}
              selected={isDocumentDropdownFilterOpen}
              handleActivate={this.toggleDocumentDropdownFilterVisiblity}
            />

            {isDocumentDropdownFilterOpen && (
              <div style={{ position: 'relative', right: '14vw' }}>
                <DropdownFilter
                  clearFilters={this.props.clearDocFilters}
                  name="Document"
                  isClearEnabled={anyDocFiltersAreSet}
                  handleClose={this.toggleDocumentDropdownFilterVisiblity}
                  addClearFiltersRow
                >
                  <DocTagPicker
                    tags={populateDocumentFilter()}
                    tagToggleStates={this.props.docFilterCriteria.document}
                    handleTagToggle={this.props.setDocFilter}
                  />
                </DropdownFilter>
              </div>
            )}
          </>

        ),
        valueFunction: (doc) => (
          <DocTypeColumn
            doc={doc}
            documentPathBase={this.props.documentPathBase}
          />
        ),
      },
      {
        cellClass: 'tags-column',
        ariaLabel: 'tag-header-label',
        header: (
          <div id="tags-header" className="document-list-header-issue-tags">
            <span id="tag-header-label">
              Issue Tags
              {anyTagFiltersAreSet ? 'Filtering by Issue Tags' : ''}
            </span>
            <FilterIcon
              label="Filter by tag"
              idPrefix="tag"
              getRef={this.getTagFilterIconRef}
              selected={isTagDropdownFilterOpen || anyTagFiltersAreSet}
              handleActivate={this.toggleTagDropdownFilterVisiblity}
            />
            {isTagDropdownFilterOpen && (
              <div style={{ position: 'relative', right: '10vw' }}>
                <DropdownFilter
                  clearFilters={this.props.clearTagFilters}
                  name="tag"
                  isClearEnabled={anyTagFiltersAreSet}
                  handleClose={this.toggleTagDropdownFilterVisiblity}
                  addClearFiltersRow
                >
                  <DocTagPicker
                    tags={this.props.tagOptions}
                    tagToggleStates={this.props.docFilterCriteria.tag}
                    handleTagToggle={this.props.setTagFilter}
                  />
                </DropdownFilter>
              </div>
            )}
          </div>
        ),
        valueFunction: (doc) => {
          return <TagTableColumn tags={doc.tags} />;
        },
      },
      {
        cellClass: 'comments-column',
        header: (
          <div id="comments-header" className="document-list-header-comments">
            Comments
          </div>
        ),
        valueFunction: (doc) => <CommentIndicator docId={doc.id} />,
      },
    ];
  };

  render() {
    const rowObjects = getRowObjects(
      this.props.documents,
      this.props.annotationsPerDocument
    );

    return (
      <div>
        <Table
          columns={this.getDocumentColumns}
          rowObjects={rowObjects}
          summary="Document list"
          className="documents-table"
          headerClassName="cf-document-list-header-row"
          bodyClassName="cf-document-list-body"
          rowsPerRowObject={2}
          tbodyId="documents-table-body"
          tbodyRef={this.getTbodyRef}
          getKeyForRow={this.getKeyForRow}
        />
      </div>
    );
  }
}

DocumentsTable.propTypes = {
  documents: PropTypes.arrayOf(PropTypes.object).isRequired,
  onJumpToComment: PropTypes.func,
  sortBy: PropTypes.string,
  pdfList: PropTypes.shape({
    lastReadDocId: PropTypes.number,
    scrollTop: PropTypes.number,
  }),
  changeSortState: PropTypes.func.isRequired,
  clearCategoryFilters: PropTypes.func,
  clearTagFilters: PropTypes.func,
  documentPathBase: PropTypes.string,
  annotationsPerDocument: PropTypes.object,
  docFilterCriteria: PropTypes.object,
  setCategoryFilter: PropTypes.func.isRequired,
  setTagFilter: PropTypes.func.isRequired,
  setDocListScrollPosition: PropTypes.func.isRequired,
  toggleDropdownFilterVisibility: PropTypes.func.isRequired,
  tagOptions: PropTypes.arrayOf(PropTypes.object).isRequired,
  setDocFilter: PropTypes.func,
  clearDocFilters: PropTypes.func,
  secretDebug: PropTypes.func
};

const mapDispatchToProps = (dispatch) =>
  bindActionCreators(
    {
      setDocListScrollPosition,
      clearTagFilters,
      clearCategoryFilters,
      setTagFilter,
      changeSortState,
      toggleDropdownFilterVisibility,
      setCategoryFilter,
      setDocFilter,
      clearDocFilters
    },
    dispatch
  );

const mapStateToProps = (state) => ({
  annotationsPerDocument: getAnnotationsPerDocument(state),
  ..._.pick(state.documentList, 'docFilterCriteria', 'pdfList'),
  ..._.pick(state.pdfViewer, 'tagOptions'),
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(DocumentsTable);
