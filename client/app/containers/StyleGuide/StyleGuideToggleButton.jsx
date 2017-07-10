import React from 'react';
import ToggleButton from '../../components/ToggleButton';
import StyleGuideComponentTitle from '../../components/StyleGuideComponentTitle';

export default class StyleGuideToggleButton extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      active: 'view_1'
    };
  }

  handleClick = (id) => {
    this.setState({ active: id });
  }
  render() {

    return <div>
    <br/>
    <StyleGuideComponentTitle
      title="Toggle buttons"
      id="toggle_buttons"
      link="StyleGuideToggleButton.jsx"
      isSubsection={true}
    />
    <div className="usa-grid">
    <ToggleButton
     labels ={[{ id: 'view_1',
       text: 'View 1' }, { id: 'view_2',
         text: 'View 2' }]}
     active ={this.state.active}
     onClick ={this.handleClick}/>
   </div>
   </div>;
  }
}

