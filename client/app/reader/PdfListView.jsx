import React, { PropTypes } from 'react';
import { connect } from 'react-redux';
import Table from '../components/Table';
import { formatDate } from '../util/DateUtil';
import { linkToSingleDocumentView } from '../components/PdfUI';
import DocumentCategoryIcons from '../components/DocumentCategoryIcons';
import DocumentListHeader from '../components/reader/DocumentListHeader';
import * as Constants from './constants';
import DropdownFilter from './DropdownFilter';
import _ from 'lodash';
import DocCategoryPicker from './DocCategoryPicker';
import IconButton from '../components/IconButton';

const FilterIcon = (props) =>
  <IconButton {...props} className={'table-icon bordered-icon'} iconName="fa-filter" />;

export class PdfListView extends React.Component {

  componentDidMount() {
    if (this.categoryFilterIcon) {
      this.props.setPosition('category', this.categoryFilterIcon.getBoundingClientRect());
    }
  }

  getDocumentColumns = () => {
    let className;

    if (this.props.sortDirection === 'ascending') {
      className = "fa-caret-down";
    } else {
      className = "fa-caret-up";
    }

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

    const toggleCategoryFilter = () => this.props.toggleCategoryFilter('category');

    // We have blank headers for the comment indicator and label indicator columns.
    // We use onMouseUp instead of onClick for filename event handler since OnMouseUp
    // is triggered when a middle mouse button is clicked while onClick isn't.
    return [
      {
        header: <div
          id="categories-header"
          className="document-list-header-categories">
          Categories <FilterIcon
            label="Filter by category"
            getRef={(categoryFilterIcon) => {
              this.categoryFilterIcon = categoryFilterIcon;
            }}
            handleActivate={toggleCategoryFilter} />

          {_.get(this.props.pdfList, ['dropdowns', 'category']) &&
            <DropdownFilter baseCoordinates={this.props.pdfList.filterPositions.category}
              handleClose={toggleCategoryFilter}>
              <DocCategoryPicker
                categoryToggleStates={this.props.pdfList.filters.category} />
            </DropdownFilter>
          }

        </div>,
        valueFunction: (doc) => <DocumentCategoryIcons docId={doc.id} />
      },
      {
        header: <div
          id="receipt-date-header"
          onClick={this.props.changeSortState('date')}>
          Receipt Date {this.props.sortBy === 'date' ? sortIcon : notsortedIcon}
        </div>,
        valueFunction: (doc) =>
          <span className="document-list-receipt-date">
            {formatDate(doc.receivedAt)}
          </span>
      },
      {
        header: <div id="type-header" onClick={this.props.changeSortState('type')}>
          Document Type {this.props.sortBy === 'type' ? sortIcon : notsortedIcon}
        </div>,
        valueFunction: (doc, index) => boldUnreadContent(
          <a
            href={linkToSingleDocumentView(doc)}
            onMouseUp={this.props.showPdf(index)}>
            {doc.type}
          </a>, doc)
      },
      {
        header: <div id="issue-tags-header"
          className="document-list-header-issue-tags"
          onClick={() => {
            // on click handler here
          }}>
          Issue Tags <FilterIcon label="Filter by issue" />
        </div>,
        valueFunction: () => {
          return <div className="document-list-issue-tags">
          </div>;
        }
      },
      {
        header: <div
          id="comments-header"
          className="document-list-header-comments"
        >
          Comments
        </div>,
        valueFunction: (doc) => {
          let numberOfComments = this.props.annotationStorage.
            getAnnotationByDocumentId(doc.id).length;

          return <span className="document-list-comments-indicator">
            {numberOfComments > 0 &&
              <span>
                <a href="#">{numberOfComments}
                  <i className=
                    "fa fa-3 fa-angle-down document-list-comments-indicator-icon" />
                </a>
              </span>
            }
          </span>;
        }
      }
    ];
  }

  render() {
    let commentSelectorClassNames = ['cf-pdf-button'];

    if (this.props.isCommentLabelSelected) {
      commentSelectorClassNames.push('cf-selected-label');
    } else {
      commentSelectorClassNames.push('cf-label');
    }

    return <div className="usa-grid">
      <div className="cf-app">
        <div className="cf-app-segment cf-app-segment--alt">
          <DocumentListHeader
            documents={this.props.documents}
            onFilter={this.props.onFilter}
            filterBy={this.props.filterBy}
            numberOfDocuments={this.props.numberOfDocuments}
          />
          <div>
            <Table
              columns={this.getDocumentColumns()}
              rowObjects={this.props.documents}
              summary="Document list"
            />
          </div>
        </div>
      </div>
    </div>;
  }
}

PdfListView.propTypes = {
  documents: PropTypes.arrayOf(PropTypes.object).isRequired,
  filterBy: PropTypes.string.isRequired,
  numberOfDocuments: PropTypes.number.isRequired,
  onFilter: PropTypes.func.isRequired,
  sortBy: PropTypes.string
};

const mapStateToProps = (state) => _.pick(state.ui, 'pdfList');
const mapDispatchToProps = (dispatch) => ({
  toggleCategoryFilter(filterName) {
    dispatch({
      type: Constants.TOGGLE_FILTER_DROPDOWN,
      payload: {
        filterName
      }
    });
  },
  setPosition(filterName, boundingRect) {
    dispatch({
      type: Constants.SET_FILTER_POSITION,
      payload: {
        filterName,
        boundingRect
      }
    });
  }
});

export default connect(mapStateToProps, mapDispatchToProps)(PdfListView);
