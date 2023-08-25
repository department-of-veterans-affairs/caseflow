/* eslint-disable max-lines */
import React from 'react';
import PropTypes from 'prop-types';
import _, { pick } from 'lodash';
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
import DateSelector from '../components/DateSelector';
import Dropdown from '../components/Dropdown';
import {
  setDocListScrollPosition,
  changeSortState,
  clearTagFilters,
  clearCategoryFilters,
  setTagFilter,
  setCategoryFilter,
  toggleDropdownFilterVisibility,
  setRecieptDateFilter
} from '../reader/DocumentList/DocumentListActions';
import { getAnnotationsPerDocument } from './selectors';
import { SortArrowDownIcon } from '../components/icons/SortArrowDownIcon';
import { SortArrowUpIcon } from '../components/icons/SortArrowUpIcon';
import { DoubleArrowIcon } from '../components/icons/DoubleArrowIcon';

import DocCategoryPicker from './DocCategoryPicker';
import DocTagPicker from './DocTagPicker';
import FilterIcon from '../components/icons/FilterIcon';
import LastReadIndicator from './LastReadIndicator';
import DocTypeColumn from './DocTypeColumn';

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

// Takes the string date returned by the date picker, compares it to a today
// and returns true if the new date was before the current day
const validateDateIsNotAfter = (pickedDate) => {
  if (new Date(pickedDate) < new Date()) {
    console.log('date was before.');
  }
};

const validateDateIsAfter = (pickedDate) => {
  if (new Date(pickedDate) > new Date()) {
    console.log('date was After.');
  }
};

const validateDayIsToday = (pickedDate) => {

  const today = new Date();
  const todaysDay = today.getDate();
  // Add 1 because months start at 0. uses padStart to turn something like 8 into 08
  const todaysMonth = String(today.getMonth() + 1).padStart(2, '0');
  const todaysYear = today.getFullYear();

  // build a date that matches the format the datetime input hands to us (YYYY-MM-DD)
  const todaysString = `${todaysYear}-${todaysMonth}-${todaysDay}`;

  if (pickedDate === todaysString) {
    console.log('date was today.');
  }

};

class DocumentsTable extends React.Component {
  constructor() {
    super();
    this.state = {
      recieptFilter: 0
    };
  }
  componentDidMount() {
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
  toggleCategoryDropdownFilterVisiblity = () =>
    this.props.toggleDropdownFilterVisibility('category');
  toggleTagDropdownFilterVisiblity = () =>
    this.props.toggleDropdownFilterVisibility('tag');

  updateRecieptFilter = (selectedKey) => {
    this.setState({
      ...this.state,
      recieptFilter: Number(selectedKey)
    });
  }

    toggleRecieptDataDropdownFilterVisibility = () => this.props.toggleDropdownFilterVisibility('receiptDate');

    getRecieptDateFilterIconRef = (recieptDataFilterIcon) => (this.recieptDataFilterIcon = recieptDataFilterIcon);

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

    const anyDateFiltersAreSet = anyFiltersSet('receiptDate');

    const dateDropdownMap = [
      { value: 0, displayText: 'Between these dates' },
      { value: 1, displayText: 'Before this date' },
      { value: 2, displayText: 'After this date' },
      { value: 3, displayText: 'On this date' }
    ];

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

    const isCategoryDropdownFilterOpen = _.get(this.props.pdfList, [
      'dropdowns',
      'category',
    ]);

    const isTagDropdownFilterOpen = _.get(this.props.pdfList, [
      'dropdowns',
      'tag',
    ]);

    const isRecipetDateFilterOpen = _.get(this.props.pdfList, [
      'dropdowns',
      'receiptDate',
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
          <div style={{ minWidth: '250px' }}>
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
            <FilterIcon
              label="Filter by dates"
              idPrefix="receiptDate"
              getRef={this.getRecieptDateFilterIconRef}
              selected={isRecipetDateFilterOpen || anyDateFiltersAreSet}
              handleActivate={this.toggleRecieptDataDropdownFilterVisibility}
            />
            {isRecipetDateFilterOpen && (
              <DropdownFilter
                clearFilters={this.props.clearTagFilters}
                name="Reciept Date"
                isClearEnabled={anyTagFiltersAreSet}
                handleClose={this.toggleRecieptDataDropdownFilterVisibility}
                addClearFiltersRow
              >
                <>
                  <Dropdown
                    name="dateDropdownText"
                    options={dateDropdownMap}
                    label="Date filter parameters"
                    value="dateDropdownVal"
                    onChange={(newKey) => this.updateRecieptFilter(newKey)}
                    defaultText={dateDropdownMap[this.state.recieptFilter].displayText}
                    defaultValue="On this date"
                  />

                  {(this.state.recieptFilter === 0 || this.state.recieptFilter === 1) &&
                  <DateSelector type="date" name="Before this date" onChange={validateDateIsNotAfter} />}
                  {(this.state.recieptFilter === 0 || this.state.recieptFilter === 2) &&
                  <DateSelector type="date" name="After this date" onChange={validateDateIsAfter} />}
                  {this.state.recieptFilter === 3 && <DateSelector type="date" name="On this date" onChange={validateDayIsToday} />}
                  <div style={{ width: '100%', display:'flex'}}>
                    <div style={{display:'flex', margin:'flex-end', justifyContent:'end'}}>
                      <Button onClick={this.props.setRecieptDateFilter} title="apply filter">
                        <span>text</span>
                      </Button>
                    </div>
                  </div>
                </>
              </DropdownFilter>
            )}
          </div>
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
  setRecieptDateFilter: PropTypes.func,
  setDocListScrollPosition: PropTypes.func.isRequired,
  toggleDropdownFilterVisibility: PropTypes.func.isRequired,
  tagOptions: PropTypes.arrayOf(PropTypes.object).isRequired,
  state: PropTypes.shape({
    recieptFilter: PropTypes.number
  })
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
      setRecieptDateFilter
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
