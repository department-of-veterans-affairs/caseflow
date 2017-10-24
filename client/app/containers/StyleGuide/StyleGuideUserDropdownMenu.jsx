import React from 'react';
import DropdownMenu from '../../components/DropdownMenu';
import StyleGuideComponentTitle from '../../components/StyleGuideComponentTitle';

export default class StyleGuideUserDropdownMenu extends React.Component {
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
        title="User dropdown menu"
        id="user_dropdown_menu"
        link="StyleGuideUserDropdownMenu.jsx"
        isSubsection={true}
      />
      <p>This menu indicates which user is signed in and contains links to submit feedback,
      view the application’s help page, see newly launched features, and log out.
      Users can view their names on the navigation bar at all times and click on
      the dropdown icon to view further options.</p>
      <DropdownMenu
        options={this.options()}
        onClick={this.handleMenuClick}
        onBlur={this.handleMenuClick}
        label="JANE AUSTIN"
        menu={this.state.menu}
      />
    </div>;
  }
}
