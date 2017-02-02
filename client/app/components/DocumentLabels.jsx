import React, { PropTypes } from 'react';
import Button from '../components/Button';

export default class DocumentLabels extends React.Component {
  constructor(props) {
    super(props);
  }

  render() {
    return <span>
      <Button
        name="blueLabel"
        classNames={["cf-pdf-bookmarks cf-pdf-button"]}
        onClick={this.props.onClick('blue')}>
        <i
          style={{ color: '#23ABF6' }}
          className="fa fa-bookmark"
          aria-hidden="true"></i>
      </Button>
      <Button
        name="orangeLbel"
        classNames={["cf-pdf-bookmarks cf-pdf-button"]}
        onClick={this.props.onClick('orange')}>
        <i
          style={{ color: '#F6A623' }}
          className="fa fa-bookmark"
          aria-hidden="true"></i>
      </Button>
      <Button
        name="whiteLabel"
        classNames={["cf-pdf-bookmarks cf-pdf-button"]}
        onClick={this.props.onClick('white')}>
        <i
          style={{ color: '#5B616B' }}
          className="fa fa-bookmark-o"
          aria-hidden="true"></i>
      </Button>
      <Button
        name="pinkLabel"
        classNames={["cf-pdf-bookmarks cf-pdf-button"]}
        onClick={this.props.onClick('pink')}>
        <i
          style={{ color: '#F772E7' }}
          className="fa fa-bookmark"
          aria-hidden="true"></i>
      </Button>
      <Button
        name="greenLabel"
        classNames={["cf-pdf-bookmarks cf-pdf-button"]}
        onClick={this.props.onClick('green')}>
        <i
          style={{ color: '#3FCD65' }}
          className="fa fa-bookmark"
          aria-hidden="true"></i>
      </Button>
      <Button
        name="yellowLabel"
        classNames={["cf-pdf-bookmarks cf-pdf-button"]}
        onClick={this.props.onClick('yellow')}>
        <i
          style={{ color: '#EFDF1A' }}
          className="fa fa-bookmark"
          aria-hidden="true"></i>
      </Button>
    </span>;
  }
}

DocumentLabels.propTypes = {
  onClick: PropTypes.func.isRequired
};
