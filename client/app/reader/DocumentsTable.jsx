import React from 'react';
import PropTypes from 'prop-types';
import _ from 'lodash';
import { connect } from 'react-redux';
import { formatDateStr } from '../util/DateUtil';
import Comment from '../components/Comment';
import { openDocumentInNewTab } from '../reader/utils';
import DocumentCategoryIcons from '../components/DocumentCategoryIcons';
import TagTableColumn from '../components/reader/TagTableColumn';
import Table from '../components/Table';
import Button from '../components/Button';
import * as Constants from './constants';
import CommentIndicator from './CommentIndicator';
import DropdownFilter from './DropdownFilter';
import { bindActionCreators } from 'redux';

import { setDocListScrollPosition, changeSortState,
  setTagFilter, setCategoryFilter } from './actions';
import { getAnnotationsPerDocument } from './selectors';
import {
  SelectedFilterIcon, UnselectedFilterIcon, rightTriangle
} from '../components/RenderFunctions';
import DocCategoryPicker from './DocCategoryPicker';
import DocTagPicker from './DocTagPicker';

const NUMBER_OF_COLUMNS = 6;

class FilterIcon extends React.PureComponent {
  render() {
    const {
      handleActivate, label, getRef, selected, idPrefix
    } = this.props;

    const handleKeyDown = (event) => {
      if (event.key === ' ' || event.key === 'Enter') {
        handleActivate(event);
        event.preventDefault();
      }
    };

    const className = 'table-icon';

    const props = {
      role: 'button',
      getRef,
      'aria-label': label,
      className,
      tabIndex: '0',
      onKeyDown: handleKeyDown,
      onClick: handleActivate
    };

    if (selected) {
      return <SelectedFilterIcon {...props} idPrefix={idPrefix} />;
    }

    return <UnselectedFilterIcon {...props} />;
  }
}

FilterIcon.propTypes = {
  label: PropTypes.string.isRequired,
  iconName: PropTypes.string,
  handleActivate: PropTypes.func,
  getRef: PropTypes.func,
  idPrefix: PropTypes.string.isRequired,
  className: PropTypes.string
};

class LastReadIndicator extends React.PureComponent {
  render() {
    if (!this.props.shouldShow) {
      return null;
    }

    return <span
      id="read-indicator"
      ref={this.props.getRef}
      aria-label="Most recently read document indicator">
        {rightTriangle()}
      </span>;
  }
}

const lastReadIndicatorMapStateToProps = (state, ownProps) => ({
  shouldShow: state.ui.pdfList.lastReadDocId === ownProps.docId
});
const ConnectedLastReadIndicator = connect(lastReadIndicatorMapStateToProps)(LastReadIndicator);

class DocumentsTable extends React.Component {
  constructor() {
    super();
    this.state = {
      filterPositions: {
        tag: {},
        category: {}
      }
    };
  }

  componentDidMount() {
    this.hasSetScrollPosition = false;
    this.setFilterIconPositions();
    window.addEventListener('resize', this.setFilterIconPositions);
  }

  componentWillUnmount() {
    this.props.setDocListScrollPosition(this.tbodyElem.scrollTop);
    window.removeEventListener('resize', this.setFilterIconPositions);
  }

  setFilterIconPositions = () => {
    this.setCategoryFilterIconPosition();
    this.setTagFilterIconPosition();
  }

  setCategoryFilterIconPosition = () => {
    this.setFilterIconPosition('category', this.categoryFilterIcon);
  }

  setTagFilterIconPosition = () => {
    this.setFilterIconPosition('tag', this.tagFilterIcon);
  }

  singleDocumentView = () => openDocumentInNewTab(this.props.documentPathBase, this.props.doc)

  getTbodyRef = (elem) => this.tbodyElem = elem
  getLastReadIndicatorRef = (elem) => this.lastReadIndicatorElem = elem
  getCategoryFilterIconRef = (categoryFilterIcon) => this.categoryFilterIcon = categoryFilterIcon
  getTagFilterIconRef = (tagFilterIcon) => this.tagFilterIcon = tagFilterIcon
  toggleCategoryDropdownFilterVisiblity = () => this.props.toggleDropdownFilterVisiblity('category')
  toggleTagDropdownFilterVisiblity = () => this.props.toggleDropdownFilterVisiblity('tag')

  getKeyForRow = (index, { isComment, id }) => {
    return isComment ? `${id}-comment` : id;
  }

  setFilterIconPosition = (filterType, icon) => {
    const boundingClientRect = {
      bottom: icon.getBoundingClientRect().bottom + window.scrollY,
      right: icon.getBoundingClientRect().right
    };

    if (this.state.filterPositions[filterType].bottom !== boundingClientRect.bottom ||
      this.state.filterPositions[filterType].right !== boundingClientRect.right) {
      this.setState({
        filterPositions: _.merge(this.state.filterPositions, {
          [filterType]: _.merge({}, boundingClientRect)
        })
      });
    }
  }

  componentDidUpdate() {
    if (!this.hasSetScrollPosition) {
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

      this.hasSetScrollPosition = true;
    }
    this.setFilterIconPositions();
  }

    // eslint-disable-next-line max-statements
  getDocumentColumns = (row) => {
    const className = this.props.docFilterCriteria.sort.sortAscending ? 'fa-caret-up' : 'fa-caret-down';

    let sortIcon = <i className={`fa fa-1 ${className} table-icon`}
      aria-hidden="true"></i>;
    let notsortedIcon = <i className="fa fa-1 fa-arrows-v table-icon"
      aria-hidden="true"></i>;

    let boldUnreadContent = (content, doc) => {
      if (!doc.opened_by_current_user) {
        return <strong>{content}</strong>;
      }

      return content;
    };

    const clearFilters = () => {
      _(Constants.documentCategories).keys().
        forEach((categoryName) => this.props.setCategoryFilter(categoryName, false));
    };

    const clearTagFilters = () => {
      _(this.props.docFilterCriteria.tag).keys().
        forEach((tagText) => this.props.setTagFilter(tagText, false));
    };

    const anyFiltersSet = (filterType) => (
      Boolean(_.some(this.props.docFilterCriteria[filterType]))
    );

    const anyCategoryFiltersAreSet = anyFiltersSet('category');
    const anyTagFiltersAreSet = anyFiltersSet('tag');

    // We have blank headers for the comment indicator and label indicator columns.
    // We use onMouseUp instead of onClick for filename event handler since OnMouseUp
    // is triggered when a middle mouse button is clicked while onClick isn't.
    if (row && row.isComment) {
      return [{
        valueFunction: (doc) => {
          const comments = this.props.annotationsPerDocument[doc.id];
          const commentNodes = comments.map((comment, commentIndex) => {
            return <Comment
              key={comment.uuid}
              id={`comment${doc.id}-${commentIndex}`}
              selected={false}
              page={comment.page}
              onJumpToComment={this.props.onJumpToComment(comment)}
              uuid={comment.uuid}
              horizontalLayout={true}>
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

    const isCategoryDropdownFilterOpen =
      _.get(this.props.pdfList, ['dropdowns', 'category']);

    const isTagDropdownFilterOpen =
      _.get(this.props.pdfList, ['dropdowns', 'tag']);

    return [
      {
        cellClass: 'last-read-column',
        valueFunction: (doc) => <ConnectedLastReadIndicator docId={doc.id} getRef={this.getLastReadIndicatorRef} />
      },
      {
        cellClass: 'categories-column',
        header: <div
          id="categories-header">
          Categories <FilterIcon
            label="Filter by category"
            idPrefix="category"
            getRef={this.getCategoryFilterIconRef}
            selected={isCategoryDropdownFilterOpen || anyCategoryFiltersAreSet}
            handleActivate={this.toggleCategoryDropdownFilterVisiblity} />

          {isCategoryDropdownFilterOpen &&
            <DropdownFilter baseCoordinates={this.state.filterPositions.category}
              clearFilters={clearFilters}
              name="category"
              isClearEnabled={anyCategoryFiltersAreSet}
              handleClose={this.toggleCategoryDropdownFilterVisiblity}>
              <DocCategoryPicker
                categoryToggleStates={this.props.docFilterCriteria.category}
                handleCategoryToggle={this.props.setCategoryFilter} />
            </DropdownFilter>
          }

        </div>,
        valueFunction: (doc) => <DocumentCategoryIcons doc={doc} />
      },
      {
        cellClass: 'receipt-date-column',
        header: <Button
          id="receipt-date-header"
          classNames={['cf-document-list-button-header']}
          onClick={() => this.props.changeSortState('receivedAt')}>
          Receipt Date {this.props.docFilterCriteria.sort.sortBy === 'receivedAt' ? sortIcon : notsortedIcon}
        </Button>,
        valueFunction: (doc) =>
          <span className="document-list-receipt-date">
            {formatDateStr(doc.receivedAt)}
          </span>
      },
      {
        cellClass: 'doc-type-column',
        header: <Button id="type-header"
        classNames={['cf-document-list-button-header']}
        onClick={() => this.props.changeSortState('type')}>
          Document Type {this.props.docFilterCriteria.sort.sortBy === 'type' ? sortIcon : notsortedIcon}
        </Button>,
        valueFunction: (doc) => boldUnreadContent(
          <a
            href={this.singleDocumentView}
            onMouseUp={this.props.showPdf(doc.id)}>
            {doc.type}
          </a>, doc)
      },
      {
        cellClass: 'tags-column',
        header: <div id="tags-header"
          className="document-list-header-issue-tags">
          Issue Tags <FilterIcon
            label="Filter by tag"
            idPrefix="tag"
            getRef={this.getTagFilterIconRef}
            selected={isTagDropdownFilterOpen || anyTagFiltersAreSet}
            handleActivate={this.toggleTagDropdownFilterVisiblity}
          />
          {isTagDropdownFilterOpen &&
            <DropdownFilter baseCoordinates={this.state.filterPositions.tag}
              clearFilters={clearTagFilters}
              name="tag"
              isClearEnabled={anyTagFiltersAreSet}
              handleClose={this.toggleTagDropdownFilterVisiblity}>
              <DocTagPicker
                tags={this.props.tagOptions}
                tagToggleStates={this.props.docFilterCriteria.tag}
                handleTagToggle={this.props.setTagFilter} />
            </DropdownFilter>
          }
        </div>,
        valueFunction: (doc) => {
          return <TagTableColumn
            doc={doc}
          />;
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

  render() {
    let rowObjects = this.props.documents.reduce((acc, row) => {
      acc.push(row);
      const doc = _.find(this.props.documents, _.pick(row, 'id'));

      if (_.size(this.props.annotationsPerDocument[doc.id]) && doc.listComments) {
        acc.push({
          ...row,
          isComment: true
        });
      }

      return acc;
    }, []);

    return <div>
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

const mapDispatchToProps = (dispatch) => ({
  ...bindActionCreators({
    setDocListScrollPosition,
    setTagFilter,
    setCategoryFilter,
    changeSortState
  }, dispatch),
  toggleDropdownFilterVisiblity(filterName) {
    dispatch({
      type: Constants.TOGGLE_FILTER_DROPDOWN,
      payload: {
        filterName
      }
    });
  }
});

const mapStateToProps = (state) => ({
  annotationsPerDocument: getAnnotationsPerDocument(state),
  ..._.pick(state, 'tagOptions'),
  ..._.pick(state.ui, 'pdfList')
});

export default connect(
  mapStateToProps, mapDispatchToProps
)(DocumentsTable);
