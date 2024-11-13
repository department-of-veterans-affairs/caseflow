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
import DocSizeIndicator from './DocSizeIndicator';
import DropdownFilter from '../components/DropdownFilter';
import { bindActionCreators } from 'redux';
import Highlight from '../components/Highlight';
import DateSelector from '../components/DateSelector';
import {
  setDocListScrollPosition,
  changeSortState,
  clearTagFilters,
  clearCategoryFilters,
  setTagFilter,
  setCategoryFilter,
  toggleDropdownFilterVisibility,
  setDocFilter,
  clearDocFilters,
  setDocTypes,
  setReceiptDateFilter
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
import ReactSelectDropdown from '../components/ReactSelectDropdown';
import { megaBitsToBytes } from './utils/network';

const NUMBER_OF_COLUMNS = 6;
const receiptDateFilterStates = {
  UNINITIALIZED: '',
  BETWEEN: 0,
  TO: 1,
  FROM: 2,
  ON: 3

};

// This needs to be called here and not from a util file. This is because the value of the
// connection.downlink is not static and needs to be calculated at runtime.

const connection = (navigator.connection || navigator.mozConnection || navigator.webkitConnection || 1);
const mbpsToBps = megaBitsToBytes(connection.downlink);

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

// made because theres occasional automagic things happening when I convert the string to date
const convertStringToDate = (stringDate) => {
  let date = new Date();
  const splitVals = stringDate.split('-');

  date.setFullYear(Number(splitVals[0]));
  // the datepicker component returns months from 1-12. Javascript dates count months from 0-11
  // this offsets it so they match.
  date.setMonth(Number(splitVals[1] - 1));
  date.setDate(Number(splitVals[2]));

  return date;
};

class DocumentsTable extends React.Component {

 validateDateFrom = (pickedDate) => {
   let foundErrors = [];

   // Prevent the from date from being after the To date.
   if (this.state.toDate !== '' && this.state.receiptFilter === receiptDateFilterStates.BETWEEN &&
   pickedDate > this.state.toDate) {
     foundErrors = [...foundErrors, 'From date cannot occur after to date.'];
   }
   // Prevent the To date and From date from being the same date.
   if (this.state.toDate !== '' && pickedDate === this.state.toDate) {
     foundErrors = [...foundErrors, 'From date and To date cannot be the same.'];
   }

   // Prevent the date from being picked past the current day.
   if (convertStringToDate(pickedDate) > new Date()) {
     foundErrors = [...foundErrors, 'Receipt date cannot be in the future.'];
   }

   if (foundErrors.length === 0) {

     this.setState({ fromDate: pickedDate,
       fromDateErrors: [] });

     return foundErrors;
   }
   this.setState({ fromDateErrors: foundErrors });

   return foundErrors;
 };

 setDateFrom = (pickedDate) => {
   this.setState({ fromDate: pickedDate
   });
 }

 validateDateTo(pickedDate) {
   let foundErrors = [];

   // Prevent setting the to date before the from date
   if (this.state.fromDate !== '' && this.state.receiptFilter === receiptDateFilterStates.BETWEEN &&
   pickedDate < this.state.fromDate) {
     foundErrors = [...foundErrors, 'To date cannot occur before from date.'];
   }

   // Prevent setting the To and From dates to the same date.
   if (this.state.fromDate !== '' && pickedDate === this.state.fromDate) {
     foundErrors = [...foundErrors, 'From date and To date cannot be the same.'];
   }

   // Prevent the date from being picked past the current day.
   if (convertStringToDate(pickedDate) > new Date()) {
     foundErrors = [...foundErrors, 'Receipt date cannot be in the future.'];
   }

   if (foundErrors.length === 0) {
     this.setState({ toDate: pickedDate,
       toDateErrors: []
     });

     return foundErrors;

   }
   this.setState({ toDateErrors: foundErrors });

   return foundErrors;

 }

 setDateTo = (pickedDate) => {
   this.setState({ toDate: pickedDate
   });
 };

 validateDateOn = (pickedDate) => {
   let foundErrors = [];

   if (convertStringToDate(pickedDate) > new Date()) {
     foundErrors = [...foundErrors, 'Receipt date cannot be in the future.'];
     this.setState({ onDateErrors: foundErrors });

     return foundErrors;
   }

   this.setState({ onDateErrors: [] });

   return foundErrors;
 }

 setOnDate = (pickedDate) => {

   this.setState({ onDate: pickedDate });
 }

  errorMessagesNode = (errors, errType) => {
    if (errors.length) {
      return (
        <div>
          {
            errors.map((error, index) =>
              <p id={`${errType}Err${index}`} key={index} style={{ color: 'red' }}>{error}</p>
            )
          }
        </div>
      );
    }
  }

  constructor() {
    super();
    this.state = {
      receiptFilter: '',
      fromDate: '',
      toDate: '',
      onDate: '',
      fromDateErrors: [],
      toDateErrors: [],
      onDateErrors: [],
      recipetFilterEnabled: true,
      fallbackState: ''
    };
  }

 executeReceiptFilter = () => {
   const toErrors = this.validateDateTo(this.state.toDate);
   const fromErrors = this.validateDateFrom(this.state.fromDate);
   const onErrors = this.validateDateOn(this.state.onDate);

   if (fromErrors.length === 0 && toErrors.length === 0 && onErrors.length === 0) {
     this.props.setReceiptDateFilter(this.state.receiptFilter,
       { fromDate: this.state.fromDate,
         toDate: this.state.toDate,
         onDate: this.state.onDate });
     this.toggleReceiptDataDropdownFilterVisibility();
   }
 }

 isReceiptFilterButtonEnabled = () => {
   let disabled = false;

   switch (this.state.receiptFilter) {
   case receiptDateFilterStates.BETWEEN:
     disabled = this.state.toDate === '' || this.state.fromDate === '';
     break;
   case receiptDateFilterStates.TO:
     disabled = this.state.toDate === '';
     break;
   case receiptDateFilterStates.FROM:
     disabled = this.state.fromDate === '';
     break;
   case receiptDateFilterStates.ON:
     disabled = this.state.onDate === '';
     break;
   case receiptDateFilterStates.UNINITIALIZED:
     disabled = true;
     break;
   default:
     disabled = false;
   }

   return disabled;
 };

 initializeReceiptFilter() {
   this.setState({
     fromDate: this.props.docFilterCriteria.receiptFilterDates.fromDate,
     toDate: this.props.docFilterCriteria.receiptFilterDates.toDate,
     onDate: this.props.docFilterCriteria.receiptFilterDates.onDate,
     receiptFilter: this.props.docFilterCriteria.receiptFilterType
   });
 }

 componentDidMount() {
   this.props.setClearAllFiltersCallbacks([this.resetReceiptPicker]);

   this.initializeReceiptFilter();

   // this if statement is what freezes the values, once it's set, it's set unless manipulated
   // back to a empty state via redux
   if (this.props.docFilterCriteria.docTypeList === '') {

     let docsArray = [];

     this.props.documents.map((x) => docsArray.includes(x.type) ? true : docsArray.push(x.type));
     // convert each item to a hash for use in the document filter
     let filterItems = [];

     docsArray.forEach((x) => filterItems.push({
       value: docsArray.indexOf(x),
       text: x
     }));

     // store the tags in redux
     this.props.setDocTypes(filterItems);
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

  updateReceiptFilter = (selectedKey) => {
    this.resetReceiptPicker();
    this.setState({
      receiptFilter: Number(selectedKey)
    });
  }

    toggleReceiptDataDropdownFilterVisibility = () => this.props.toggleDropdownFilterVisibility('receiptDate');

    getReceiptDateFilterIconRef = (receiptDataFilterIcon) => (this.receiptDataFilterIcon = receiptDataFilterIcon);

    resetReceiptPicker = () => {
      this.props.setReceiptDateFilter({});
      // eslint-disable-next-line max-len
      this.setState({ receiptFilter: '', receiptFilterType: '', fromDate: '', toDate: '', onDate: '', fromDateErrors: [], toDateErrors: [], onDateErrors: [] });
    };
  getKeyForRow = (index, { isComment, id }) => {
    return isComment ? `${id}-comment` : `${id}`;
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

    const anyDateFiltersAreSet = anyFiltersSet('receiptDate');

    const dateDropdownMap = [
      { value: 0, label: 'Between these dates' },
      { value: 1, label: 'Before this date' },
      { value: 2, label: 'After this date' },
      { value: 3, label: 'On this date' }
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

    const isDocumentDropdownFilterOpen = _.get(this.props.pdfList, [
      'dropdowns',
      'document',
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
            <span id="categories-header-label" className="table-header-label">
              Categories
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
              styling={{ 'aria-roledescription': 'sort button', style: { display: 'inline' } }}
              name="Receipt Date"
              id="receipt-date-header"
              classNames={['cf-document-list-button-header']}
              onClick={() => this.props.changeSortState('receivedAt')}
            >
              <span id="receipt-date-header-label" className="table-header-label">Receipt Date</span>
              {this.props.docFilterCriteria.sort.sortBy === 'receivedAt' ?
                sortArrowIcon :
                notSortedIcon}
            </Button>
            {this.props.featureToggles.readerSearchImprovements && <FilterIcon
              label="Filter by dates"
              idPrefix="receiptDate"
              getRef={this.getreceiptDateFilterIconRef}
              selected={isRecipetDateFilterOpen || anyDateFiltersAreSet}
              handleActivate={this.toggleReceiptDataDropdownFilterVisibility}
            />}
            {isRecipetDateFilterOpen && (
              <div style={{
                position: 'relative',
                right: '7vw'
              }}>
                <DropdownFilter
                  clearFilters={this.resetReceiptPicker}
                  name="Receipt Date"
                  isClearEnabled
                  handleClose={this.toggleReceiptDataDropdownFilterVisibility}
                  addClearFiltersRow
                >
                  <div>
                    <div style={{ padding: '0px 30px' }}>
                      <ReactSelectDropdown
                        options={dateDropdownMap}
                        defaultValue={dateDropdownMap[this.state.receiptFilter]}
                        label="Date filter parameters"
                        onChangeMethod={(selectedOption) => this.updateReceiptFilter(selectedOption.value)}
                        featureToggles={this.props.featureToggles}
                        className="date-filter-type-dropdown"
                      />
                      {
                        (this.state.receiptFilter === receiptDateFilterStates.BETWEEN ||
                        this.state.receiptFilter === receiptDateFilterStates.FROM) &&
                        <DateSelector
                          value={this.state.fromDate}
                          type="date"
                          name={this.state.receiptFilter === receiptDateFilterStates.BETWEEN ? 'From' : ''}
                          onChange={this.setDateFrom}
                          errorMessage={this.errorMessagesNode(this.state.fromDateErrors, 'fromDate')}
                          id="receipt-date-from"
                        />
                      }

                      {
                        (this.state.receiptFilter === receiptDateFilterStates.BETWEEN ||
                        this.state.receiptFilter === receiptDateFilterStates.TO) &&
                        <DateSelector
                          value={this.state.toDate}
                          type="date"
                          name={this.state.receiptFilter === receiptDateFilterStates.BETWEEN ? 'To' : ''}
                          onChange={this.setDateTo}
                          errorMessage={this.errorMessagesNode(this.state.toDateErrors, 'toDate')}
                          id="receipt-date-to"
                        />
                      }

                      {this.state.receiptFilter === receiptDateFilterStates.UNINITIALIZED &&
                      <DateSelector readOnly type="date" name="Receipt date"
                        onChange={this.validateDateIsAfter} comment="This is a read only component used as a dummy" />}

                      {this.state.receiptFilter === receiptDateFilterStates.ON &&
                        <DateSelector
                          value={this.state.onDate}
                          type="date"
                          name={this.state.receiptFilter === receiptDateFilterStates.BETWEEN ? 'On' : ''}
                          onChange={this.setOnDate}
                          errorMessage={this.errorMessagesNode(this.state.onDateErrors, 'onDate')}
                          id="receipt-date-on"
                        />}
                    </div>

                    <div>
                      <div style={{ width: '100%', display: 'flex' }}>
                        <span
                          style={{ height: '1px', position: 'absolute', width: '100%', backgroundColor: 'gray' }}>
                        </span>
                        <div style={{ display: 'flex', margin: '10px 0px', justifyContent: 'center', width: '100%' }}>
                          <Button
                            disabled={this.isReceiptFilterButtonEnabled()}
                            onClick={() => this.executeReceiptFilter()}
                            title="apply filter"
                          >
                            <span>Apply filter</span>
                          </Button>
                        </div>
                      </div>
                    </div>
                  </div>
                </DropdownFilter></div>
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
          <>
            <Button
              id="type-header"
              styling={{ 'aria-roledescription': 'sort button', style: { display: 'inline' } }}
              name="Document Type"
              classNames={['cf-document-list-button-header']}
              onClick={() => this.props.changeSortState('type')}
            >
              <span id="type-header-label" className="table-header-label">Document Type</span>

              {this.props.docFilterCriteria.sort.sortBy === 'type' ?
                sortArrowIcon :
                notSortedIcon}
            </Button>
            {this.props.featureToggles.readerSearchImprovements && <FilterIcon
              label="Filter by Document"
              idPrefix="document"
              getRef={this.getDocumentFilterIconRef}
              selected={isDocumentDropdownFilterOpen}
              handleActivate={this.toggleDocumentDropdownFilterVisiblity}
            />}
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
                    tags={this.props.docFilterCriteria.docTypeList}
                    tagToggleStates={this.props.docFilterCriteria.document}
                    handleTagToggle={this.props.setDocFilter}
                    defaultSearchText="Type to search..."
                    featureToggles={this.props.featureToggles}

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
            <span id="tag-header-label" className="table-header-label">
              Issue Tags
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
                    defaultSearchText="Type to search..."
                    featureToggles={this.props.featureToggles}
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
          <div id="comments-header" className="document-list-header-comments table-header-label">
            Comments
          </div>
        ),
        valueFunction: (doc) => <CommentIndicator docId={doc.id} />,
      },
      {
        cellClass: 'comments-column',
        header: (
          <div id="comments-header" className="document-list-header-comments table-header-label">
            File Size
          </div>
        ),
        valueFunction: (doc) => <DocSizeIndicator docSize={doc.file_size} browserSpeedInBytes={mbpsToBps} warningThreshold={parseInt(doc.max_wait_time, 10)} />,
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
  setReceiptDateFilter: PropTypes.func,
  setDocListScrollPosition: PropTypes.func.isRequired,
  toggleDropdownFilterVisibility: PropTypes.func.isRequired,
  tagOptions: PropTypes.arrayOf(PropTypes.object).isRequired,
  setDocFilter: PropTypes.func,
  setDocTypes: PropTypes.func,
  clearDocFilters: PropTypes.func,
  secretDebug: PropTypes.func,
  setClearAllFiltersCallbacks: PropTypes.func.isRequired,
  featureToggles: PropTypes.object
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
      clearDocFilters,
      setDocTypes,
      setReceiptDateFilter
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
