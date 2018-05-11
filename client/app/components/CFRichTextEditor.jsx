import React from 'react';
import PropTypes from 'prop-types';
import { convertToRaw, EditorState, ContentState } from 'draft-js';
import draftToHtml from 'draftjs-to-html';
import htmlToDraft from 'html-to-draftjs';
import { Editor } from 'react-draft-wysiwyg';
import classNamesFn from 'classnames';
import { css } from 'glamor';

const styles = css({
  border: '1px solid #323a45',
  resize: 'vertical'
});

export default class CFRichTextEditor extends React.PureComponent {

  constructor(props) {
    super(props);
    this.state = {
      editorState: EditorState.createEmpty()
    };
  }

  componentDidMount = () => {
    const { value } = this.props;
    const contentBlock = htmlToDraft(value);

    const contentState = ContentState.createFromBlockArray(contentBlock.contentBlocks);
    const editorState = EditorState.createWithContent(contentState);

    if (value) {
      this.setState({ editorState });
    }
  };

  onChange = (value) => {
    this.setState({
      value,
      editorState: value
    });

    if (this.props.onChange) {
      // Send the changes up to the parent component as an HTML string.
      this.props.onChange(draftToHtml(convertToRaw(this.state.editorState.getCurrentContent())));
    }
  };

  render() {
    const {
      errorMessage,
      hideLabel,
      id,
      label,
      name,
      required,
      toolbar
    } = this.props;

    return <div>
      <label className={classNamesFn({ 'sr-only': hideLabel }, 'question-label')} htmlFor={id || name}>
        {label || name} {required && <span className="cf-required">Required</span>}
      </label>
      {errorMessage && <span className="usa-input-error-message">{errorMessage}</span>}
      <div {...styles}>
        <Editor
          onEditorStateChange={this.onChange}
          editorState={this.state.editorState}
          editorClassName="demo-editor"
          toolbar={toolbar}
          wrapperId={id}
        />
      </div>
    </div>;
  }
}

CFRichTextEditor.propTypes = {
  sections: PropTypes.arrayOf(
    PropTypes.shape({
      activated: PropTypes.boolean,
      title: PropTypes.string
    })
  )
};
