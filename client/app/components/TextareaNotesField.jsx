import React from 'react';
import PropTypes from 'prop-types';

import TextareaField from './TextareaField';

export default class TextareaNotesField extends React.PureComponent {
  render() {
    const {
      errorMessage,
      onChange,
      value
    } = this.props;

    return <TextareaField
      name="Notes"
      id="taskInstructions"
      errorMessage={errorMessage}
      onChange={onChange}
      value={value}
      aria-label="Notes"
      disabled={false}
      hideLabel={false}
    />;
  }
}

TextareaNotesField.propTypes = {
  errorMessage: PropTypes.string,
  onChange: PropTypes.func.isRequired,
  value: PropTypes.string
};
