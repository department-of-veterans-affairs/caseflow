import React, { PropTypes } from 'react';
import Table from '../components/Table';
import { formatDate } from '../util/DateUtil';
import StringUtil from '../util/StringUtil';
import { linkToSingleDocumentView } from '../components/PdfUI';
import DocumentListHeader from '../components/reader/DocumentListHeader';

export default class PdfListView extends React.Component {
  getDocumentColumns = () => {
    let className;

    if (this.props.sortDirection === 'ascending') {
      className = "fa-caret-down";
    } else {
      className = "fa-caret-up";
    }

    let sortIcon = <i className={`fa fa-1 ${className} table-icon`}
      aria-hidden="true"></i>;
    let filterIcon = <i className="fa fa-1 fa-filter table-icon bordered-icon"
      aria-hidden="true"></i>;
    let notsortedIcon = <i className="fa fa-1 fa-arrows-v table-icon"
      aria-hidden="true"></i>;

    let boldUnreadContent = (content, doc) => {
      if (!doc.opened_by_current_user) {
        return <b>{content}</b>;
      }

      return content;
    };

    // We have blank headers for the comment indicator and label indicator columns.
    // We use onMouseUp instead of onClick for filename event handler since OnMouseUp
    // is triggered when a middle mouse button is clicked while onClick isn't.
    return [
      {
        header: <div
          id="categories-header"
          className="document-list-header-categories"
          onClick={() => {
            // on click actions here
          }}>
          Categories {filterIcon}
        </div>,
        valueFunction: (doc) => {
          return <span>
            {doc.label && <i
              className={`fa fa-bookmark cf-pdf-bookmark-` +
                `${StringUtil.camelCaseToDashCase(doc.label)}`}
              aria-hidden="true"></i>}
          </span>;
        }
      },
      {
        header: <div
          id="receipt-date-header"
          className="document-list-header-recepit-date"
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
          Issue Tags {filterIcon}
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
