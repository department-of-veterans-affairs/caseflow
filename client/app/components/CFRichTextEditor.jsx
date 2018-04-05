import React from 'react';
import PropTypes from 'prop-types';
import RichTextEditor from 'react-rte';

export default class CFRichTextEditor extends React.PureComponent {

  constructor(props) {
    super(props);
    this.state = {
      value: RichTextEditor.createEmptyValue()
    };
  }

  static getDerivedStateFromProps(nextProps){
    const { value } = nextProps;
    console.log(value);
    if (value) {
      this.setState({ value })
    }
  }

  onChange = (value) => {
    this.setState({ value });
    if (this.props.onChange) {
      // Send the changes up to the parent component as an HTML string.
      // This is here to demonstrate using `.toString()` but in a real app it
      // would be better to avoid generating a string on each change.
      this.props.onChange(value.toString('markdown'));
    }
  };

  render() {
    const {
      errorMessage,
      hideLabel,
      id,
      maxlength,
      label,
      name,
      required,
      type,
      value,
      styling
    } = this.props;
    
    return <div>
      <RichTextEditor onChange={this.onChange} value={this.state.value} />
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
