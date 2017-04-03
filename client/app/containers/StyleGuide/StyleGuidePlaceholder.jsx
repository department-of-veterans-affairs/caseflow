import React, { PropTypes } from 'react';

export default class StyleGuidePlaceholder extends React.Component {
  render(){
    let {
      id,
      title
    } = this.props;

    return <div>
      <div className="cf-sg-placeholder">
        <h2 id={id}>{title}</h2>
      </div>
      <div>
        <p>This component is not ready yet. Stay tuned! :) </p>
      </div>
    </div>
  }

}
