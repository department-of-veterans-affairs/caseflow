import React, { PropTypes } from 'react';
import Button from '../components/Button';

export default class DocumentLabels extends React.Component {
  render() {
    return <span>
      <Button
        name="blueLabel"
        classNames={["cf-pdf-bookmarks cf-pdf-button"]}
        onClick={this.props.onClick('blue')}>
        <i
          className="fa fa-bookmark cf-pdf-bookmark-blue"
          aria-hidden="true"></i>
      </Button>
      <Button
        name="orangeLabel"
        classNames={["cf-pdf-bookmarks cf-pdf-button"]}
        onClick={this.props.onClick('orange')}>
        <i
          className="fa fa-bookmark cf-pdf-bookmark-orange"
          aria-hidden="true"></i>
      </Button>
      <Button
        name="whiteLabel"
        classNames={["cf-pdf-bookmarks cf-pdf-button"]}
        onClick={this.props.onClick('white')}>
        <i
          className="fa fa-bookmark-o cf-pdf-bookmark-white-outline"
          aria-hidden="true"></i>
      </Button>
      <Button
        name="pinkLabel"
        classNames={["cf-pdf-bookmarks cf-pdf-button"]}
        onClick={this.props.onClick('pink')}>
        <i
          className="fa fa-bookmark cf-pdf-bookmark-pink"
          aria-hidden="true"></i>
      </Button>
      <Button
        name="greenLabel"
        classNames={["cf-pdf-bookmarks cf-pdf-button"]}
        onClick={this.props.onClick('green')}>
        <i
          className="fa fa-bookmark cf-pdf-bookmark-green"
          aria-hidden="true"></i>
      </Button>
      <Button
        name="yellowLabel"
        classNames={["cf-pdf-bookmarks cf-pdf-button"]}
        onClick={this.props.onClick('yellow')}>
        <i
          className="fa fa-bookmark cf-pdf-bookmark-yellow"
          aria-hidden="true"></i>
      </Button>
    </span>;
  }
}

DocumentLabels.propTypes = {
  onClick: PropTypes.func.isRequired
};
