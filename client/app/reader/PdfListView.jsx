import React, { PropTypes } from 'react';
import Table from '../components/Table';
import DocumentLabels from '../components/DocumentLabels';
import { formatDate } from '../util/DateUtil';
import SearchBar from '../components/SearchBar';
import StringUtil from '../util/StringUtil';
import Button from '../components/Button';
import Comment from '../components/Comment';

import { linkToSingleDocumentView } from '../components/PdfUI';

export default class PdfListView extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      commentsOpened: {}
    }
  }

  toggleComments = (id) => () => {
    let commentsOpened = {...this.state.commentsOpened, [id]: !this.state.commentsOpened[id]};

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

    let sortIcon = <i className={`fa ${className}`} aria-hidden="true"></i>;

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
                id={`comment${doc.id}-${commentIndex}`}
                selected={false}
                page={comment.page}
                onJumpToComment={this.props.onJumpToComment(doc.id, comment.uuid)}
                uuid={comment.uuid}>
                  {comment.comment}
                </Comment>;
            });
            return <div>
              {commentNodes}
            </div>;
          },
          span: (doc) => {
            return 5;
          }
        }]
      }
      return [{
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
          header: <div onClick={this.props.changeSortState('date')}>
            Receipt Date {this.props.sortBy === 'date' ? sortIcon : ' '}
          </div>,
          valueFunction: (doc) => boldUnreadContent(formatDate(doc.receivedAt), doc)
        },
        {
          header: <div onClick={this.props.changeSortState('type')}>
            Document Type {this.props.sortBy === 'type' ? sortIcon : ' '}
          </div>,
          valueFunction: (doc) => boldUnreadContent(doc.type, doc)
        },
        {
          header: <div onClick={this.props.changeSortState('filename')}>
            Filename {this.props.sortBy === 'filename' ? sortIcon : ' '}
          </div>,
          valueFunction: (doc) => {
            return boldUnreadContent(
              <a
                href={linkToSingleDocumentView(doc)}
                onMouseUp={this.props.showPdf(doc.id)}>
                {doc.filename}
              </a>, doc);
          }
        },
        {
          header: "Comments",
          valueFunction: (doc) => {
            let comments = this.props.annotationStorage.
              getAnnotationByDocumentId(doc.id);
            let numberOfComments = comments.length;

            if (numberOfComments === 0) {
              return;
            }

            return boldUnreadContent(
              <a
                href="#"
                onClick={this.toggleComments(doc.id)}>
                {numberOfComments} Comments
              </a>, doc);
          }
        }
      ]};
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
        let commentRow = {...row};
        commentRow.isComment = true;
        acc.push(commentRow);
      }
      return acc;
    }, []);

    return <div className="usa-grid">
      <div className="cf-app">
        <div className="cf-app-segment cf-app-segment--alt">
          <div className="usa-grid-full">
            <div className="usa-width-one-third">
              <SearchBar onChange={this.props.onFilter} value={this.props.filterBy} />
            </div>
            <div className="usa-width-one-third">
              <span>
                Show only:
                <DocumentLabels
                  onClick={this.props.selectLabel}
                  selectedLabels={this.props.selectedLabels} />
              </span>
              <span>
                <Button
                  name="comment-selector"
                  onClick={this.props.selectComments}
                  classNames={commentSelectorClassNames}>
                  <i className="fa fa-comment-o fa-lg"></i>
                </Button>
              </span>
            </div>
            <div className="usa-width-one-third">
              <span className="cf-right-side">
                Showing {`${this.props.documents.length} out of ` +
                `${this.props.numberOfDocuments}`} documents
              </span>
            </div>
          </div>
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
  onJumpToComment: PropTypes.func
};
