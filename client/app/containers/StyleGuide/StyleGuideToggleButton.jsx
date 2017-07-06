import React from 'react';
import Button from '../../components/Button';
import StyleGuideComponentTitle from '../../components/StyleGuideComponentTitle';

export default class StyleGuideToggleButton extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
       isToggleOn: true
        
    };
    this.handleClick = this.handleClick.bind(this);
  }

   handleClick() {
    this.setState(prevState => ({
      isToggleOn: !prevState.isToggleOn
    }));
  }
  render() {


  return <div>
    <br/>
    <StyleGuideComponentTitle
      title="Toggle button"
      id="toggle_buttons"
      link="StyleGuideToggleButton.jsx"
      isSubsection={true}
    />
    <div className="usa-grid">
    <Button
      id="view_1"
      name={'View 1'}
      classNames={['button_wrapper']}>
    </Button>
     <Button
        id="view_2"
        name={'View 2'}
        classNames={['usa-button-outline']}>
    </Button>


   </div>
   </div>;
  }
}

