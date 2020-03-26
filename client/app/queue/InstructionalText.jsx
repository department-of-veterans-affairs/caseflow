import Button from '../components/Button';
import * as React from 'react';
import { css } from 'glamor';
import PropTypes from 'prop-types';

const verticalLine = css(
  {
    borderLeft: 'thick solid lightgrey',
    marginLeft: '20px',
    paddingLeft: '20px',
    marginTop: '10px'
  }
);

const headerSpacing = css({ marginBottom: '10px' });

export default class InstructionalText extends React.PureComponent {
    linkClicked = false;
    render = () => {
      return <div><Button
        id="informational-button"
        linkStyling
        willNeverBeLoading
        onClick={() => {
          this.linkClicked = !this.linkClicked;
          this.setState({ linkClicked: this.linkClicked,
            linkArrowDirection: this.linkClicked ? 'down' : 'right' });
        }}>
        {this.props.informationalTitle}
      </Button>
      { this.linkClicked && <div {...verticalLine}>
        <div {...headerSpacing}>{this.props.informationHeader}</div>
        <ol>
          <li>{this.props.bulletOne}</li>
          <li> {this.props.bulletTwo}</li>
          <li> {this.props.bulletThree}</li>
        </ol>
      </div>}
      </div>;
    }

}

InstructionalText.propTypes = {
  informationalTitle: PropTypes.string,
  informationHeader: PropTypes.string,
  bulletOne: PropTypes.string,
  bulletTwo: PropTypes.string,
  bulletThree: PropTypes.string
};
