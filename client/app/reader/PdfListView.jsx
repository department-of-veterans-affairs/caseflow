import React, { PropTypes } from 'react';
import Table from '../components/Table';
import { formatDate } from '../util/DateUtil';
import StringUtil from '../util/StringUtil';
import Comment from '../components/Comment';
import Button from '../components/Button';
import { linkToSingleDocumentView } from '../components/PdfUI';
import DocumentListHeader from '../components/reader/DocumentListHeader';
import _ from 'lodash';

const NUMBER_OF_COLUMNS = 5;

export default class PdfListView extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      commentsOpened: {}
    };
  }

  toggleComments = (id) => () => {
    let commentsOpened = {
      ...this.state.commentsOpened,
      [id]: !this.state.commentsOpened[id]
    };

    this.setState({
      commentsOpened
    });
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
    return (row) => {
      if (row && row.isComment) {
        return [{
          valueFunction: (doc) => {
            let comments = this.props.annotationStorage.
              getAnnotationByDocumentId(doc.id);
            let commentNodes = comments.map((comment, commentIndex) => {
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

            return <ul ariaLabel="Document comments">
              {commentNodes}
            </ul>;
          },
          span: _.constant(NUMBER_OF_COLUMNS)
        }];
      }

      return [
        {
          header: <div
            id="categories-header"
            className="document-list-header-categories">
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
          valueFunction: (doc) => boldUnreadContent(
            <a
              href={linkToSingleDocumentView(doc)}
              onMouseUp={this.props.showPdf(doc.id)}>
              {doc.type}
            </a>, doc)
        },
        {
          header: <div id="issue-tags-header"
            className="document-list-header-issue-tags">
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
            let icon = `fa fa-3 ${this.state.commentsOpened[row.id] ?
              'fa-angle-up' : 'fa-angle-down'}`;
            let name = `expand ${numberOfComments} comments`;

            return <span className="document-list-comments-indicator">
              {numberOfComments > 0 &&
                <span>
                  <Button
                    classNames={["cf-btn-link"]}
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
      if (this.state.commentsOpened[row.id]) {
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
          <DocumentListHeader
            documents={this.props.documents}
            onFilter={this.props.onFilter}
            filterBy={this.props.filterBy}
            numberOfDocuments={this.props.numberOfDocuments}
          />
          <div>
            <Table
              columns={this.getDocumentColumns()}
              rowObjects={rowObjects}
              summary="Document list"
              rowsPerRowObject={2}
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
  onJumpToComment: PropTypes.func,
  sortBy: PropTypes.string
};
