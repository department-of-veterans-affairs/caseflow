import Button from '../components/Button';
import * as React from 'react';
import { css } from 'glamor';
const verticalLine = css(
  {
    borderLeft: 'thick solid lightgrey',
    marginLeft: '20px',
    paddingLeft: '20px'
  }
);

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
        <div>{this.props.informationHeader}</div>
        <br />
        <div>{this.props.bulletOne}</div>
        <div> {this.props.bulletTwo}</div>
        <div> {this.props.bulletThree}</div>
      </div>}
      </div>;
    }

}
