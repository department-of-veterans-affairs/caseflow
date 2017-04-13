import React from 'react';
import DropdownMenu from '../../components/DropdownMenu';
import StyleGuideComponentTitle from '../../components/StyleGuideComponentTitle';

export default class StyleGuideDropdownMenu extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      menu: false
    };
  }

  handleMenuClick = () => {
    this.setState((prevState) => ({
      menu: !prevState.menu
    }));
  };

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
      onClick={this.handleMenuClick()}
      onBlur={this.handleMenuClick()}
      label="JANE AUSTIN"
      />
    </div>;
  }
}
