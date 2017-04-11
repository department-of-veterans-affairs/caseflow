import React from 'react';
import DropdownMenu from '../../components/DropdownMenu';
import StyleGuideComponentTitle from '../../components/StyleGuideComponentTitle';

export default class StyleGuideDropdownMenu extends React.Component {
  options = () => {
    return [
      {
        title: 'Change Location',
        link: '#dropdown_menu'
      },
      {
        title: 'Escalate to Coach',
        link: '#dropdown_menu'
      },
      {
        title: 'Cancel',
        link: '#dropdown_menu'
      }
    ];
  }

  render() {
    return <div>
      <br />
      <StyleGuideComponentTitle
        title="Dropdown Menu"
        id="dropdown_menu"
        link="StyleGuideDropdownMenu.jsx"
      />
    <DropdownMenu
      options={this.options()}
      label="JANE AUSTIN"
      />
    </div>;
  }
}
