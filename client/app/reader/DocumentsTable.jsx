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
  setDocFilter,
  clearDocFilters,
  setDocTypes,
  setRecieptDateFilter
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

const NUMBER_OF_COLUMNS = 6;

const recieptDateFilterStates = {
  UNINITIALIZED: '',
  BETWEEN: 0,
  TO: 1,
  FROM: 2,
  ON: 3

};

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
   if (this.state.toDate !== '' && pickedDate > this.state.toDate) {
     foundErrors = [...foundErrors, 'From date cannot occur after to date.'];
   }
   // Prevent the To date and From date from being the same date.
   if (this.state.toDate !== '' && pickedDate === this.state.toDate) {
     foundErrors = [...foundErrors, 'From date and To date cannot be the same.'];
   }

   // Prevent the date from being picked past the current day.
   if (convertStringToDate(pickedDate) > new Date()) {
     foundErrors = [...foundErrors, 'Reciept date cannot be in the future.'];
   }

   if (foundErrors.length === 0) {

     this.setState({ fromDate: pickedDate,
       fromDateErrors: [] });
   } else {
     this.setState({ fromDateErrors: foundErrors });
   }
 };

 validateDateTo = (pickedDate) => {
   let foundErrors = [];

   // Prevent setting the to date before the from date
   if (this.state.fromDate !== '' && pickedDate < this.state.fromDate) {
     foundErrors = [...foundErrors, 'To date cannot occur before from date.'];
   }

   // Prevent setting the To and From dates to the same date.
   if (pickedDate === this.state.fromDate) {
     foundErrors = [...foundErrors, 'From date and To date cannot be the same.'];
   }

   // Prevent the date from being picked past the current day.
   if (convertStringToDate(pickedDate) > new Date()) {
     foundErrors = [...foundErrors, 'Reciept date cannot be in the future.'];
   }

   if (foundErrors.length === 0) {
     this.setState({ toDate: pickedDate,
       toDateErrors: []
     });
   } else {
     this.setState({ toDateErrors: [foundErrors] });
   }
 }

 setOnDate = (pickedDate) => {
   let foundErrors = [];

   if (convertStringToDate(pickedDate) > new Date()) {
     foundErrors = [...foundErrors, 'Reciept date cannot be in the future.'];
   }

   if (foundErrors.length === 0) {

     this.setState({ onDate: pickedDate,
       onDateErrors: []
     });
   } else {
     this.setState({ onDateErrors: [foundErrors] });
   }
 };

 constructor() {
   super();
   this.state = {
     recieptFilter: '',
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

 executeRecieptFilter = () => {
   this.props.setRecieptDateFilter(this.state.recieptFilter,
     { fromDate: this.state.fromDate,
       toDate: this.state.toDate,
       onDate: this.state.onDate });

   this.toggleRecieptDataDropdownFilterVisibility();
 }

 isRecieptFilterButtonEnabled = () => {
   if (this.state.recieptFilter === recieptDateFilterStates.BETWEEN && (this.state.toDate === '' || this.state.fromDate === '' ||
  this.state.toDateErrors.length > 0 || this.state.fromDateErrors.length > 0)) {
     return true;
   }

   if (this.state.recieptFilter === recieptDateFilterStates.TO && (this.state.toDate === '' || this.state.fromDateErrors.length > 0)) {
     return true;
   }

   if (this.state.recieptFilter === recieptDateFilterStates.FROM && (this.state.fromDate === '' || this.state.toDateErrors.length > 0)) {
     return true;
   }

   if (this.state.recieptFilter === recieptDateFilterStates.ON && (this.state.onDate === '' || this.state.onDateErrors.length > 0)) {
     return true;
   }

   if (this.state.recieptFilter === recieptDateFilterStates.UNINITIALIZED) {
     return true;
   }

   return false;
 }
 componentDidMount() {

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

  updateRecieptFilter = (selectedKey) => {
    this.resetRecieptPicker();
    this.setState({
      recieptFilter: Number(selectedKey)
    });
  }

    toggleRecieptDataDropdownFilterVisibility = () => this.props.toggleDropdownFilterVisibility('receiptDate');

    getRecieptDateFilterIconRef = (recieptDataFilterIcon) => (this.recieptDataFilterIcon = recieptDataFilterIcon);

    resetRecieptPicker = () => {
      this.props.setRecieptDateFilter({});
      this.setState({ fromDate: '', toDate: '', onDate: '', fromDateErrors: [], toDateErrors: [], onDateErrors: [] });
    };
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
            <span id="categories-header-label">
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
              getRef={this.getreceiptDateFilterIconRef}
              selected={isRecipetDateFilterOpen || anyDateFiltersAreSet}
              handleActivate={this.toggleRecieptDataDropdownFilterVisibility}
            />
            {isRecipetDateFilterOpen && (
              <div style={{
                position: 'relative',
                right: '7vw' }}>
                <DropdownFilter
                  clearFilters={this.resetRecieptPicker}
                  name="Receipt Date"
                  isClearEnabled
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
                      defaultText={this.state.recieptFilter === recieptDateFilterStates.UNINITIALIZED ? 'Select...' :
                        dateDropdownMap[this.state.recieptFilter].displayText}
                      defaultValue="On this date"
                    />
                    {(this.state.recieptFilter === recieptDateFilterStates.BETWEEN || this.state.recieptFilter === recieptDateFilterStates.FROM) &&
                  this.state.fromDateErrors.map((error, index) =>
                    <p id={index} key={index} style={{ color: 'red' }}>{error}</p>)}
                    {(this.state.recieptFilter === recieptDateFilterStates.BETWEEN || this.state.recieptFilter === recieptDateFilterStates.FROM) &&
                  <DateSelector value={this.state.fromDate} type="date" name="From"
                    onChange={this.validateDateFrom} />}

                    {(this.state.recieptFilter === recieptDateFilterStates.BETWEEN || this.state.recieptFilter === recieptDateFilterStates.TO) &&
                  this.state.toDateErrors.map((error) =>
                    <p style={{ color: 'red' }}>{error}</p>)}
                    {(this.state.recieptFilter === recieptDateFilterStates.BETWEEN || this.state.recieptFilter === recieptDateFilterStates.TO) &&
                  <DateSelector value={this.state.toDate} type="date" name="To"
                    onChange={this.validateDateTo} />}

                    {this.state.recieptFilter === recieptDateFilterStates.UNINITIALIZED && <DateSelector readOnly type="date" name="Receipt date"
                      onChange={this.validateDateIsAfter} comment="This is a read only component used as a dummy" />}

                    {(this.state.recieptFilter === recieptDateFilterStates.ON) && this.state.onDateErrors.map((error) =>
                      <p style={{ color: 'red' }}>{error}</p>)}
                    {this.state.recieptFilter === recieptDateFilterStates.ON && <DateSelector value={this.state.onDate} type="date"
                      name="On this date" onChange={this.setOnDate} />}

                    <div style={{ width: '100%', display: 'flex' }}>
                      <span style={{ height: '1px', position: 'absolute', width: '100%', backgroundColor: 'gray' }}></span>
                      <div style={{ display: 'flex', marginTop: '10px', marginRight: '10px', marginBottom: '10px', justifyContent: 'end', width: '100%' }}>
                        <Button disabled={this.isRecieptFilterButtonEnabled()} onClick={() => this.executeRecieptFilter()} title="apply filter">
                          <span>Apply filter</span>
                        </Button>
                      </div>
                    </div>
                  </>
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
                    tags={this.props.docFilterCriteria.docTypeList}
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
  setRecieptDateFilter: PropTypes.func,
  setDocListScrollPosition: PropTypes.func.isRequired,
  toggleDropdownFilterVisibility: PropTypes.func.isRequired,
  tagOptions: PropTypes.arrayOf(PropTypes.object).isRequired,
  setDocFilter: PropTypes.func,
  setDocTypes: PropTypes.func,
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
      clearDocFilters,
      setDocTypes,
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
