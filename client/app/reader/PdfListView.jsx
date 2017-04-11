import React, { PropTypes } from 'react';
import Table from '../components/Table';
import DocumentLabels from '../components/DocumentLabels';
import { formatDate } from '../util/DateUtil';
import StringUtil from '../util/StringUtil';
import Button from '../components/Button';
import { linkToSingleDocumentView } from '../components/PdfUI';
import DocumentListHeader from './DocumentListHeader';

export default class PdfListView extends React.Component {
  getDocumentColumns = () => {
    let className;

    if (this.props.sortDirection === 'ascending') {
      className = "fa-caret-down";
    } else {
      className = "fa-caret-up";
    }

    let sortIcon = <i className={`fa fa-1 ${className} table-icon`} aria-hidden="true"></i>;
    let filterIcon = <i className="fa fa-1 fa-filter table-icon bordered-icon" aria-hidden="true"></i>;

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
          id="receipt-date-header"
          onClick={() => { console.log("Categories filter clicked.")}}>
          Categories {filterIcon}
        </div>,
        valueFunction: (doc) => {
          return <span>
            {doc.label && <i
            className={`fa fa-bookmark cf-pdf-bookmark-` +
              `${StringUtil.camelCaseToDashCase(doc.label)}`}
            aria-hidden="true"></i> }
          </span>;
        }
      },
      {
        header: <div
          id="receipt-date-header"
          onClick={this.props.changeSortState('date')}>
          Receipt Date {this.props.sortBy === 'date' ? sortIcon : ' '}
        </div>,
        valueFunction: (doc) =>
          <span className="document-list-receipt-date">
           {formatDate(doc.receivedAt)}
          </span>
      },
      {
        header: <div id="type-header" onClick={this.props.changeSortState('type')}>
          Document Type {this.props.sortBy === 'date' ? sortIcon : ' '}
        </div>,
        valueFunction: (doc, index) => boldUnreadContent(
          <a
            href={linkToSingleDocumentView(doc)}
            onMouseUp={this.props.showPdf(index)}>
            {doc.type}
          </a>, doc)
      },
      {
        header: <div id="type-header" onClick={() => console.log("Issue tags filter clicked.")}>
          Issue Tags {filterIcon}
        </div>,
        valueFunction: (doc) => {
          let tags = ['SC - Knee', 'Dislocated Shoulder'];
          let tagItems = tags.map((tag) =>
            <span className="document-list-issue-tag">tag</span>
          );
          console.log(tagItems);
          return <div className="document-list-issue-tags">
            {tagItems}
          </div>;
        }
      },
      {
        header: <div id="type-header">
          Comments
        </div>,
        valueFunction: (doc) => {
          let numberOfComments = this.props.annotationStorage.
            getAnnotationByDocumentId(doc.id).length;

          return <span className="document-list-comments-indicator">
            { numberOfComments > 0 &&
              <span>
                <a href="#">{numberOfComments}
                  <i className="fa fa-3 fa-angle-down document-list-comments-indicator-icon"/>
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
  onFilter: PropTypes.func.isRequired
};
