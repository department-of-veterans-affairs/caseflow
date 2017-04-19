import React, { PropTypes } from 'react';
import { formatDate } from '../util/DateUtil';
import Comment from '../components/Comment';
import SearchableDropdown from '../components/SearchableDropdown';
import EditComment from '../components/EditComment';
import _ from 'lodash';
import Checkbox from '../components/Checkbox';
import Alert from '../components/Alert';
import { connect } from 'react-redux';
import * as Constants from '../reader/constants';
import ApiUtil from '../util/ApiUtil';
import { categoryFieldNameOfCategoryName } from '../reader/utils';

const FIRST_ELEMENT = 0;

const CategorySelector = (props) => {
  const { category, categoryName, handleCategoryToggle, docId, documents } = props;
  const toggleState = _.get(
    documents,
    [docId, categoryFieldNameOfCategoryName(categoryName)],
    false
  );
  const Svg = category.svg;
  const label = <div className="cf-category-selector">
      <Svg />
      <span className="cf-category-name">{category.humanName}</span>
    </div>;

  const handleChange = (checked) => handleCategoryToggle(categoryName, checked, docId);

  return <div>
    <Checkbox name={categoryName} onChange={handleChange}
      label={label} value={toggleState} />
  </div>;
};

CategorySelector.propTypes = {
  category: PropTypes.shape({
    humanName: PropTypes.string.isRequired,
    svg: PropTypes.func.isRequired
  }).isRequired,
  categoryName: PropTypes.string.isRequired
};

const mapPropsToState = (state) => _.pick(state, 'documents');
const mapDispatchToState = (dispatch) => ({
  handleCategoryToggle(categoryName, toggleState, docId) {
    const categoryKey = categoryFieldNameOfCategoryName(categoryName);

    ApiUtil.patch(
      `/document/${docId}`,
      { data: { [categoryKey]: toggleState } }
    ).catch((err) => {
      // eslint-disable-next-line no-console
      console.log('Saving document category failed', err);
    });

    dispatch({
      type: Constants.TOGGLE_DOCUMENT_CATEGORY,
      payload: {
        categoryName,
        toggleState,
        docId
      }
    });
  }
});
const ConnectedCategorySelector = connect(
    mapPropsToState, mapDispatchToState
  )(CategorySelector);

// PdfSidebar shows relevant document information and comments.
// It is intended to be used with the PdfUI component to
// show a PDF with it's corresponding information.
export default class PdfSidebar extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      values: [],
      options: []
    };
  }

  generateOptionsFromTags = (tags) => {

    if (!tags || tags.length <= 0) {
      return {};
    }

    return tags.map((tag) => {
      return { value: tag.text,
        label: tag.text,
        tagId: tag.id };
    });
  };

  updateOptionsFromTagsInState = (tags) => {
    this.setState(() => {
      return {
        options: this.generateOptionsFromTags(tags)
      };
    });
  };

  updateValuesFromTagsInState = (tags) => {
    this.setState(() => {
      return {
        values: this.generateOptionsFromTags(tags)
      };
    });
  };

  componentWillReceiveProps = (nextProps) => {
    this.updateOptionsFromTagsInState(nextProps.doc.tags);
    this.updateValuesFromTagsInState(nextProps.doc.tags);
  }


  render() {
    let comments = [];

    const {
      doc,
      tagsErrorMessage
    } = this.props;

    comments = this.props.comments.map((comment, index) => {
      if (comment.uuid === this.props.editingComment) {
        return <EditComment
            id="editCommentBox"
            onCancelCommentEdit={this.props.onCancelCommentEdit}
            onSaveCommentEdit={this.props.onSaveCommentEdit}
            key={comment.comment}
          >
            {comment.comment}
          </EditComment>;
      }

      return <Comment
        id={`comment${index}`}
        selected={false}
        onDeleteComment={this.props.onDeleteComment}
        onEditComment={this.props.onEditComment}
        uuid={comment.uuid}
        selected={comment.selected}
        onClick={this.props.onJumpToComment}
        key={comment.comment}>
          {comment.comment}
        </Comment>;
    });

    return <div className="cf-sidebar-wrapper">
        <div className="cf-document-info-wrapper">
          <div className="cf-heading-alt">
            Related Issues
          </div>
          {/* This error alert needs to be formatted according to #1573 */}
          {tagsErrorMessage &&
            <Alert type="error" title={''}
              message={tagsErrorMessage} />}
          <SearchableDropdown
            name="tags"
            label="Click in the box below to select, type, or add in issue(s)"
            multi={true}
            creatable={true}
            options={this.state.options}
            placeholder="Select or type issue"
            value={this.generateOptionsFromTags(doc.tags)}
            onChange={(values, deletedValue) => {
              if (deletedValue && deletedValue.length > 0) {
                let tagValue = deletedValue[FIRST_ELEMENT].label;
                let result = _.find(this.state.options, { 'value': tagValue });

                this.props.removeTag(doc, result.tagId);
              } else {
                this.props.addNewTag(doc, values);
              }
            }}
          />
          <div className="cf-heading-alt">Document</div>
          <p className="cf-pdf-meta-title">
            <b>Filename:</b> {this.props.doc.filename}
          </p>
          <p className="cf-pdf-meta-title">
            <b>Document Type:</b> {this.props.doc.type}
          </p>
          <p className="cf-pdf-meta-title">
            <b>Receipt Date:</b> {formatDate(this.props.doc.receivedAt)}
          </p>
          <div className="cf-heading-alt">
            Comments
            <span className="cf-right-side">
              <a href="#" onClick={this.props.onAddComment}>+ Add a Comment</a>
            </span>
          </div>
        </div>

        <div className="cf-comment-wrapper">
          <div className="cf-pdf-comment-list">
            {this.props.isAddingComment &&
              <EditComment
                id="addComment"
                onCancelCommentEdit={this.props.onCancelCommentAdd}
                onSaveCommentEdit={this.props.onSaveCommentAdd} />}
            {comments}
          </div>
        </div>
      </div>;
  }
}

PdfSidebar.propTypes = {
  onAddComment: PropTypes.func,
  doc: PropTypes.object,
  comments: React.PropTypes.arrayOf(React.PropTypes.shape({
    comment: React.PropTypes.string,
    uuid: React.PropTypes.number
  })),
  editingComment: React.PropTypes.number,
  isAddingComment: PropTypes.bool,
  onSaveCommentAdd: PropTypes.func,
  onSaveCommentEdit: PropTypes.func,
  onCancelCommentEdit: PropTypes.func,
  onCancelCommentAdd: PropTypes.func,
  onDeleteComment: PropTypes.func,
  onJumpToComment: PropTypes.func
};
