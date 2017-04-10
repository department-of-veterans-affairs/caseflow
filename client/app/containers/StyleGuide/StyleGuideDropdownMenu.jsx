import React from 'react';
import DropdownMenu from '../../components/DropdownMenu';
import StyleGuideComponentTitle from '../../components/StyleGuideComponentTitle';

export default class StyleGuideDropdownMenu extends React.Component {
  render(){
    let options = [
      {
        title: 'Change Location',
        link: '#'
      },
      {
        title: 'Escalate to Coach',
        link: '#'
      },
      {
        title: 'Cancel',
        link: '#'
      }
    ]

    return <div>
      <br />
      <StyleGuideComponentTitle
        title="Dropdown Menu"
        id="dropdown_menu"
        link="StyleGuideDropdownMenu.jsx"
      />
    <DropdownMenu
      options={options}
      label="JANE AUSTEN" />
    </div>
  }
}
