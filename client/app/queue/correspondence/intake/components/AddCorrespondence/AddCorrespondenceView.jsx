/* eslint-disable max-lines */
import React from 'react';
import PropTypes from 'prop-types';
import _ from 'lodash';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

import Table from '../../../../../components/Table';
import Button from '../../../../../components/Button';
import Checkbox from '../../../../../components/Checkbox';

const priorMailAnswer = [
  { displayText: 'Yes',
    value: 'yes' },
  { displayText: 'No',
    value: 'no' }
];
const NUMBER_OF_COLUMNS = 6;

const [selectedValue, setSelectedValue] = useState('no');

const handleRadioChange = (event) => {
  setSelectedValue(event);
};

/*
const correspondenceColumns = [
  {
    valueName: 'checkbox'
  },
  {
    header: <h3>VA DOR</h3>,
    valueName: 'va_dor'
  },
  {
    header: <h3>Source Type</h3>,
    valueName: 'source_type'
  },
  {
    header: <h3>Package Document Type</h3>,
    valueName: 'package_document_type'
  },
  {
    header: <h3>Correspondence Type</h3>,
    valueName: 'correspondence_type'
  },
  {
    header: <h3>Notes</h3>,
    valueName: 'notes'
  }
];

const getRowObjects = [
  {
    checkbox: <Checkbox name={getKeyForRow} hideLabel="true" />,
    va_dor: '09/14/2023' || 'Null',
    source_type: <a href="https://www.google.com">Mail</a> || 'Source Type Error',
    package_document_type: '10182' || 'Package Type Error',
    correspondence_type: 'Evidence or argument' || 'Correspondence Type Error',
    notes: 'This is an example of notes for correspondence' || 'Notes Error'
  },
  {
    checkbox: <Checkbox name="2" hideLabel="true" />,
    va_dor: '09/15/2023' || 'Null',
    source_type: <a href="https://www.google.com">Mail</a> || 'Source Type Error',
    package_document_type: '10182' || 'Package Type Error',
    correspondence_type: 'Evidence or argument' || 'Correspondence Type Error',
    notes: 'This is an example of notes for correspondence' || 'Notes Error'
  },
  {
    checkbox: <Checkbox name="3" hideLabel="true" />,
    va_dor: '09/16/2023' || 'Null',
    source_type: <a href="https://www.google.com">Mail</a> || 'Source Type Error',
    package_document_type: '10182' || 'Package Type Error',
    correspondence_type: 'Evidence or argument' || 'Correspondence Type Error',
    notes: 'This is an example of notes for correspondence' || 'Notes Error'
  },
];

*/

//To-Do Maybe, dawg.  We ain't be doin'
export const getRowObjects = (correspondence, correspondenceCount) => {
  return correspondence.reduce((acc, corr) => {
    acc.push(corr);
    const corrCorrespondences = _.size(correspondenceCount[corr.id]);

    if (corrCorrespondences && corr.listComments) {
      acc.push({
        ...corr,
        hasCorrespondence: true,
      });
    }

    return acc;
  }, []);
};

// made because theres occasional automagic things happening when I convert the string to date

class AddCorrespondenceView extends React.Component {

  constructor() {
    super();
    this.state = {
      checked: false,
      veteran_id: '',
      va_date_of_receipt: '',
      source_type: '',
      package_document_type: '',
      correspondence_type_id: '',
      notes: ''
    };
  }

  getKeyForRow = (index, { hasCorrespondence, id }) => {
    return hasCorrespondence ? `${id}-comment` : `${id}`;
  };

  // eslint-disable-next-line max-statements
  getDocumentColumns = () => {
    // We have blank headers for the comment indicator and label indicator columns.
    // We use onMouseUp instead of onClick for filename event handler since OnMouseUp
    // is triggered when a middle mouse button is clicked while onClick isn't.
    return [
      {
        cellClass: 'checkbox',

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

AddCorrespondenceView.propTypes = {
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
)(AddCorrespondenceView);
