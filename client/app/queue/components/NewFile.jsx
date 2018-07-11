import React from 'react';
import { NewFileIcon } from '../components/RenderFunctions';

export default class NewFile extends React.PureComponent {
  render = () => {
    if (appeal.hasNewFiles) {
      return <NewFileIcon />;
    } else {
      return null
    }
  }
}

NewFile.propTypes = {
  appeal: PropTypes.shape({
    hasNewFiles: PropTypes.bool
  }).isRequired,
};
