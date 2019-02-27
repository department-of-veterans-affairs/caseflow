/* eslint-disable max-lines */
import React from 'react';
import PropTypes from 'prop-types';
import _ from 'lodash';
import { connect } from 'react-redux';
import { css } from 'glamor';

import * as Constants from './constants';
import { formatDateStr } from '../util/DateUtil';
import Comment from './Comment';
import DocumentCategoryIcons from './DocumentCategoryIcons';
import TagTableColumn from './TagTableColumn';
import FilterableTable from '../components/FilterableTable';
import Button from '../components/Button';
import CommentIndicator from './CommentIndicator';
import { bindActionCreators } from 'redux';
import Highlight from '../components/Highlight';
import {
  setDocListScrollPosition,
  changeSortState,
  setTagFilter,
  setCategoryFilter
} from '../reader/DocumentList/DocumentListActions';
import { getAnnotationsPerDocument } from './selectors';
import {
  SortArrowUp,
  SortArrowDown,
  DoubleArrow
} from '../components/RenderFunctions';
import LastReadIndicator from './LastReadIndicator';
import DocTypeColumn from './DocTypeColumn';

const NUMBER_OF_COLUMNS = 6;

const categoryLabelStyling = css({
  display: 'flex',
  alignItems: 'flex-start',
  marginBottom: 0,
  paddingBottom: 0
});
const categoryNameStyling = css({
  lineHeight: 1,
  paddingLeft: '7px'
});

export const getRowObjects = (documents, annotationsPerDocument) => {
  return documents.reduce((acc, doc) => {
    acc.push(doc);
    const docHasComments = _.size(annotationsPerDocument[doc.id]);

    if (docHasComments && doc.listComments) {
      acc.push({
        ...doc,
        isComment: true
      });
    }

    return acc;
  }, []);
};

class DocumentsTable extends React.Component {
  componentDidMount() {
    if (this.props.pdfList.scrollTop) {
      this.tbodyElem.scrollTop = this.props.pdfList.scrollTop;

      if (this.lastReadIndicatorElem) {
        const lastReadBoundingRect = this.lastReadIndicatorElem.getBoundingClientRect();
        const tbodyBoundingRect = this.tbodyElem.getBoundingClientRect();
        const lastReadIndicatorIsInView = tbodyBoundingRect.top <= lastReadBoundingRect.top &&
          lastReadBoundingRect.bottom <= tbodyBoundingRect.bottom;

        if (!lastReadIndicatorIsInView) {
          const rowWithLastRead = _.find(
            this.tbodyElem.children,
            (tr) => tr.querySelector(`#${this.lastReadIndicatorElem.id}`)
          );

          this.tbodyElem.scrollTop += rowWithLastRead.getBoundingClientRect().top - tbodyBoundingRect.top;
        }
      }
    }
  }

  componentWillUnmount() {
    this.props.setDocListScrollPosition(this.tbodyElem.scrollTop);
  }

  getTbodyRef = (elem) => this.tbodyElem = elem
  getLastReadIndicatorRef = (elem) => this.lastReadIndicatorElem = elem
  getKeyForRow = (index, { isComment, id }) => {
    return isComment ? `${id}-comment` : id;
  }

  getCustomCategoryFilterOptions = () => {
    const activeFilters = this.props.docFilterCriteria.category;

    return _(Constants.documentCategories).
      toPairs().
      // eslint-disable-next-line no-unused-vars
      sortBy(([name, category]) => category.renderOrder).
      map(([categoryName, category]) => {
        return {
          value: categoryName,
          displayText: <div {...categoryLabelStyling}>
            {category.svg}
            <span {...categoryNameStyling}>{category.humanName}</span>
          </div>,
          checked: activeFilters[categoryName] ? activeFilters[categoryName] : false
        };
      }).
      value();
  }

  getCustomTagFilterOptions = () => {
    const rowObjects = getRowObjects(
      this.props.documents,
      this.props.annotationsPerDocument
    );
    const activeFilters = this.props.docFilterCriteria.tag;
    let tagFilters = [];
    let uniqueOptions = [];

    // Generate the unique possible tags in the data
    rowObjects.forEach((row) => {
      row.tags.forEach((tag) => {
        tagFilters.push(tag.text);
      });
    });
    tagFilters = _.uniq(tagFilters);

    // Create filter option for each tag
    uniqueOptions = tagFilters.map((filter) => {
      return {
        value: filter,
        displayText: _.capitalize(filter),
        checked: !!activeFilters[filter]
      };
    });

    uniqueOptions.push({
      value: 'null',
      displayText: '<<blank>>',
      checked: !!activeFilters['null']
    });

    return uniqueOptions;
  }

  // eslint-disable-next-line max-statements
  getDocumentColumns = (row) => {
    const sortArrowIcon = this.props.docFilterCriteria.sort.sortAscending ? <SortArrowUp /> : <SortArrowDown />;
    const notSortedIcon = <DoubleArrow />;

    // We have blank headers for the comment indicator and label indicator columns.
    // We use onMouseUp instead of onClick for filename event handler since OnMouseUp
    // is triggered when a middle mouse button is clicked while onClick isn't.
    if (row && row.isComment) {

      return [{
        valueFunction: (doc) => {
          const comments = _.sortBy(this.props.annotationsPerDocument[doc.id], ['page', 'y']);
          const commentNodes = comments.map((comment, commentIndex) => {
            return <Comment
              key={comment.uuid}
              id={`comment${doc.id}-${commentIndex}`}
              selected={false}
              page={comment.page}
              onJumpToComment={this.props.onJumpToComment(comment)}
              uuid={comment.uuid}
              date={comment.relevant_date}
              horizontalLayout>
              {comment.comment}
            </Comment>;
          });

          return <ul className="cf-no-styling-list" aria-label="Document comments">
            {commentNodes}
          </ul>;
        },
        span: _.constant(NUMBER_OF_COLUMNS)
      }];
    }

    return [
      {
        cellClass: 'last-read-column',
        valueFunction: (doc) => <LastReadIndicator docId={doc.id} getRef={this.getLastReadIndicatorRef} />
      },
      {
        cellClass: 'categories-column',
        header: 'Categories',
        enableFilter: true,
        tableData: getRowObjects(
          this.props.documents,
          this.props.annotationsPerDocument
        ),
        columnName: 'category',
        label: 'Filter by category',
        customFilterOptions: this.getCustomCategoryFilterOptions(),
        valueFunction: (doc) => <DocumentCategoryIcons doc={doc} />
      },
      {
        cellClass: 'receipt-date-column',
        header: <Button
          name="Receipt Date"
          id="receipt-date-header"
          classNames={['cf-document-list-button-header']}
          onClick={() => this.props.changeSortState('receivedAt')}>
          Receipt Date {this.props.docFilterCriteria.sort.sortBy === 'receivedAt' ? sortArrowIcon : notSortedIcon }
        </Button>,
        valueFunction: (doc) => <span className="document-list-receipt-date">
          <Highlight>
            {formatDateStr(doc.receivedAt)}
          </Highlight>
        </span>
      },
      {
        cellClass: 'doc-type-column',
        header: <Button id="type-header"
          name="Document Type"
          classNames={['cf-document-list-button-header']}
          onClick={() => this.props.changeSortState('type')}>
          Document Type {this.props.docFilterCriteria.sort.sortBy === 'type' ? sortArrowIcon : notSortedIcon }
        </Button>,
        valueFunction: (doc) => <DocTypeColumn doc={doc}
          documentPathBase={this.props.documentPathBase} />
      },
      {
        cellClass: 'tags-column',
        header: 'Issue Tags',
        enableFilter: true,
        tableData: getRowObjects(
          this.props.documents,
          this.props.annotationsPerDocument
        ),
        columnName: 'tags',
        label: 'Filter by issue tags',
        customFilterOptions: this.getCustomTagFilterOptions(),
        valueFunction: (doc) => {
          return <TagTableColumn tags={doc.tags} />;
        }
      },
      {
        cellClass: 'comments-column',
        header: <div
          id="comments-header"
          className="document-list-header-comments">
          Comments
        </div>,
        valueFunction: (doc) => <CommentIndicator docId={doc.id} />
      }
    ];
  }

  updateFilters = (filteredByList) => {
    const categoryFilters = _.keys(Constants.documentCategories);
    const tagFilters = this.getCustomTagFilterOptions().map((filterOption) => {
      return filterOption.value;
    });

    categoryFilters.forEach((filter) => {
      if (filteredByList.category && filteredByList.category.includes(filter)) {
        this.props.setCategoryFilter(filter, true);
      } else {
        this.props.setCategoryFilter(filter, false);
      }
    });

    tagFilters.forEach((filter) => {
      if (filteredByList.tags && filteredByList.tags.includes(filter)) {
        this.props.setTagFilter(filter, true);
      } else {
        this.props.setTagFilter(filter, false);
      }
    });
  }

  render() {
    const rowObjects = getRowObjects(
      this.props.documents,
      this.props.annotationsPerDocument
    );

    return <div>
      <FilterableTable
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
        onFilterChange={this.updateFilters}
        disableInternalDataFiltering
      />
    </div>;
  }
}

DocumentsTable.propTypes = {
  documents: PropTypes.arrayOf(PropTypes.object).isRequired,
  onJumpToComment: PropTypes.func,
  sortBy: PropTypes.string,
  pdfList: PropTypes.shape({
    lastReadDocId: PropTypes.number
  })
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  setDocListScrollPosition,
  setTagFilter,
  changeSortState,
  setCategoryFilter
}, dispatch);

const mapStateToProps = (state) => ({
  annotationsPerDocument: getAnnotationsPerDocument(state),
  ..._.pick(state.documentList, 'docFilterCriteria', 'pdfList'),
  ..._.pick(state.pdfViewer, 'tagOptions')
});

export default connect(
  mapStateToProps, mapDispatchToProps
)(DocumentsTable);
