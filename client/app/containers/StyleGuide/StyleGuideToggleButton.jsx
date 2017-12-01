import React from 'react';
import ToggleButton from '../../components/ToggleButton';
import Button from '../../components/Button';
import StyleGuideComponentTitle from '../../components/StyleGuideComponentTitle';

export default class StyleGuideToggleButton extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      active: 'view1'
    };
  }

  handleClick = (name) => {
    this.setState({ active: name });
  }
  render() {
    return <div>
     <StyleGuideComponentTitle
       title="Toggle buttons"
       id="toggle_buttons"
       link="StyleGuideToggleButton.jsx"
       isSubsection={true}
     />
     <ToggleButton active={this.state.active}
       onClick={this.handleClick}>
      <Button
       name="view1">
       View 1
      </Button>
      <Button
       name="view2">
       View 2
      </Button>
     </ToggleButton>
    </div>;
  }
}

