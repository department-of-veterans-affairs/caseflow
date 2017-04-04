import React, { PropTypes } from 'react';

export default class StyleGuidePlaceholder extends React.Component {
  render(){
    let {
      id,
      subsection,
      title
    } = this.props;

    return <div>
      {subsection && <div className="cf-sg-placeholder">
        <h3 id={id}>{title}</h3>
      </div>}
      {!subsection && <div className="cf-sg-placeholder">
        <h2 id={id}>{title}</h2>
      </div>}
      <div>
        <p>This component is not ready yet. Stay tuned! :) </p>
      </div>
    </div>
  }
}

StyleGuidePlaceholder.props = {
  id: PropTypes.string.isRequired,
  subsection: PropTypes.bool,
  title: PropTypes.string.isRequired
};
