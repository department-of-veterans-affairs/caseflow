import React, { PropTypes } from 'react';
import { connect } from 'react-redux';
import Table from '../components/Table';
import { formatDateStr } from '../util/DateUtil';
import Comment from '../components/Comment';
import Button from '../components/Button';
import { linkToSingleDocumentView } from '../components/PdfUI';
import DocumentCategoryIcons from '../components/DocumentCategoryIcons';
import DocumentListHeader from '../components/reader/DocumentListHeader';
import TagTableColumn from '../components/reader/TagTableColumn';
import * as Constants from './constants';
import DropdownFilter from './DropdownFilter';
import _ from 'lodash';
import DocCategoryPicker from './DocCategoryPicker';
import DocTagPicker from './DocTagPicker';
import { getAnnotationByDocumentId } from './utils';
import {
  SelectedFilterIcon, UnselectedFilterIcon, rightTriangle
} from '../components/RenderFunctions';

const NUMBER_OF_COLUMNS = 6;

const FilterIcon = ({
  handleActivate, label, getRef, selected, idPrefix
}) => {
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
};

FilterIcon.propTypes = {
  label: PropTypes.string.isRequired,
  iconName: PropTypes.string,
  handleActivate: PropTypes.func,
  getRef: PropTypes.func,
  idPrefix: PropTypes.string.isRequired,
  className: PropTypes.string
};

export class PdfListView extends React.Component {
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
    if (this.lastReadElement) {
      const boundingBox = this.lastReadElement.getBoundingClientRect();
      const halfWindowHeight = window.innerHeight / 2;

      document.body.scrollTop = boundingBox.top - halfWindowHeight;
    }

    this.setFilterIconPositions();
    window.addEventListener('resize', this.setFilterIconPositions);
  }

  componentWillUnmount() {
    window.removeEventListener('resize', this.setFilterIconPositions);
  }

  componentDidUpdate() {
    this.setFilterIconPositions();
  }

  setCategoryFilterIconPosition = () => {
    this.setFilterIconPosition('category', this.categoryFilterIcon);
  }

  setTagFilterIconPosition = () => {
    this.setFilterIconPosition('tag', this.tagFilterIcon);
  }

  setFilterIconPositions = () => {
    this.setCategoryFilterIconPosition();
    this.setTagFilterIconPosition();
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

  toggleComments = (id) => () => {
    this.props.handleToggleCommentOpened(id);
  }

  getDocumentColumns = () => {
    const className = this.props.docFilterCriteria.sort.sortAscending ? 'fa-caret-up' : 'fa-caret-down';

    let sortIcon = <i className={`fa fa-1 ${className} table-icon`}
      aria-hidden="true"></i>;
    let notsortedIcon = <i className="fa fa-1 fa-arrows-v table-icon"
      aria-hidden="true"></i>;

    let boldUnreadContent = (content, doc) => {
      if (!doc.opened_by_current_user) {
        return <b>{content}</b>;
      }

      return content;
    };

    const toggleCategoryDropdownFilterVisiblity = () =>
      this.props.toggleDropdownFilterVisiblity('category');

    const toggleTagDropdownFilterVisiblity = () =>
      this.props.toggleDropdownFilterVisiblity('tag');

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
    return (row) => {
      if (row && row.isComment) {
        return [{
          valueFunction: (doc) => {
            const comments = this.props.getAnnotationByDocumentId(doc.id);
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
          valueFunction: (doc) => {
            if (doc.id === this.props.pdfList.lastReadDocId) {
              return <span
                id="read-indicator"
                aria-label="Most recently read document indicator"
                ref={(element) => {
                  this.lastReadElement = element;
                }}>
                  {rightTriangle()}
                </span>;
            }
          }
        },
        {
          cellClass: 'categories-column',
          header: <div
            id="categories-header"
            className="document-list-header-categories">
            Categories <FilterIcon
              label="Filter by category"
              idPrefix="category"
              getRef={(categoryFilterIcon) => {
                this.categoryFilterIcon = categoryFilterIcon;
              }}
              selected={isCategoryDropdownFilterOpen || anyCategoryFiltersAreSet}
              handleActivate={toggleCategoryDropdownFilterVisiblity} />

            {isCategoryDropdownFilterOpen &&
              <DropdownFilter baseCoordinates={this.state.filterPositions.category}
                clearFilters={clearFilters}
                name="category"
                isClearEnabled={anyCategoryFiltersAreSet}
                handleClose={toggleCategoryDropdownFilterVisiblity}>
                <DocCategoryPicker
                  categoryToggleStates={this.props.docFilterCriteria.category}
                  handleCategoryToggle={this.props.setCategoryFilter} />
              </DropdownFilter>
            }

          </div>,
          valueFunction: (doc) => <DocumentCategoryIcons docId={doc.id} />
        },
        {
          cellClass: 'receipt-date-column',
          header: <div
            id="receipt-date-header"
            className="document-list-header-recepit-date"
            onClick={() => this.props.changeSortState('receivedAt')}>
            Receipt Date {this.props.docFilterCriteria.sort.sortBy === 'receivedAt' ? sortIcon : notsortedIcon}
          </div>,
          valueFunction: (doc) =>
            <span className="document-list-receipt-date">
              {formatDateStr(doc.receivedAt)}
            </span>
        },
        {
          cellClass: 'doc-type-column',
          header: <div id="type-header" onClick={() => this.props.changeSortState('type')}>
            Document Type {this.props.docFilterCriteria.sort.sortBy === 'type' ? sortIcon : notsortedIcon}
          </div>,
          valueFunction: (doc) => boldUnreadContent(
            <a
              href={linkToSingleDocumentView(this.props.documentPathBase, doc)}
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
              getRef={(tagFilterIcon) => {
                this.tagFilterIcon = tagFilterIcon;
              }}
              selected={isTagDropdownFilterOpen || anyTagFiltersAreSet}
              handleActivate={toggleTagDropdownFilterVisiblity}
            />
            {isTagDropdownFilterOpen &&
              <DropdownFilter baseCoordinates={this.state.filterPositions.tag}
                clearFilters={clearTagFilters}
                name="tag"
                isClearEnabled={anyTagFiltersAreSet}
                handleClose={toggleTagDropdownFilterVisiblity}>
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
          valueFunction: (doc) => {
            const numberOfComments = this.props.getAnnotationByDocumentId(doc.id).length;
            const icon = `fa fa-3 ${doc.listComments ?
              'fa-angle-up' : 'fa-angle-down'}`;
            const name = `expand ${numberOfComments} comments`;

            return <span className="document-list-comments-indicator">
              {numberOfComments > 0 &&
                <span>
                  <Button
                    classNames={['cf-btn-link']}
                    href="#"
                    ariaLabel={name}
                    name={name}
                    id={`expand-${doc.id}-comments-button`}
                    onClick={this.toggleComments(doc.id)}>{numberOfComments}
                    <i className={`document-list-comments-indicator-icon ${icon}`}/>
                  </Button>
                </span>
              }
            </span>;
          }
        }
      ];
    };
  }

  render() {
    let commentSelectorClassNames = ['cf-pdf-button'];

    if (this.props.isCommentLabelSelected) {
      commentSelectorClassNames.push('cf-selected-label');
    } else {
      commentSelectorClassNames.push('cf-label');
    }

    let rowObjects = this.props.documents.reduce((acc, row) => {
      acc.push(row);
      const doc = _.find(this.props.documents, _.pick(row, 'id'));

      if (this.props.getAnnotationByDocumentId(row.id).length &&
        doc.listComments) {
        acc.push({
          ...row,
          isComment: true
        });
      }

      return acc;
    }, []);

    return <div className="usa-grid">
      <div className="cf-app">
        <div className="cf-app-segment cf-app-segment--alt">
          <DocumentListHeader documents={this.props.documents} />
          <div>
            <Table
              columns={this.getDocumentColumns()}
              rowObjects={rowObjects}
              summary="Document list"
              className="documents-table"
              headerClassName="cf-document-list-header-row"
              bodyClassName="cf-document-list-body"
              rowsPerRowObject={2}
            />
          </div>
        </div>
      </div>
    </div>;
  }
}

const mapStateToProps = (state) => ({
  getAnnotationByDocumentId: _.partial(getAnnotationByDocumentId, state),
  ..._.pick(state, 'tagOptions', 'annotations'),
  ..._.pick(state.ui, 'pdfList', 'docFilterCriteria')
});

const mapDispatchToProps = (dispatch) => ({
  changeSortState(sortBy) {
    dispatch({
      type: Constants.SET_SORT,
      payload: {
        sortBy
      }
    });
  },
  toggleDropdownFilterVisiblity(filterName) {
    dispatch({
      type: Constants.TOGGLE_FILTER_DROPDOWN,
      payload: {
        filterName
      }
    });
  },
  setCategoryFilter(categoryName, checked) {
    dispatch({
      type: Constants.SET_CATEGORY_FILTER,
      payload: {
        categoryName,
        checked
      }
    });
  },
  setTagFilter(text, checked) {
    dispatch({
      type: Constants.SET_TAG_FILTER,
      payload: {
        text,
        checked
      }
    });
  },
  handleToggleCommentOpened(docId) {
    dispatch({
      type: Constants.TOGGLE_COMMENT_LIST,
      payload: {
        docId
      }
    });
  }
});

export default connect(
  mapStateToProps, mapDispatchToProps
)(PdfListView);

PdfListView.propTypes = {
  documents: PropTypes.arrayOf(PropTypes.object).isRequired,
  annotations: PropTypes.arrayOf(PropTypes.object).isRequired,
  onJumpToComment: PropTypes.func,
  sortBy: PropTypes.string,
  handleToggleCommentOpened: PropTypes.func.isRequired,
  pdfList: PropTypes.shape({
    lastReadDocId: PropTypes.number
  })
};
