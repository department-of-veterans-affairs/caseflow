import React from 'react';

export default class ChildNavLink extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      menu: false
    };
  }

  showSubMenu = () => {
    this.setState((prevState) => ({
      menu: !prevState.menu
    }));
  }

  componentDidMount = () => window.addEventListener('click', this.showSubMenu);

  render() {
    const {
      links
    } = this.props;

    return this.state.menu && <ul className="usa-sidenav-sub_list">
      { links.map((link, i) => {
        return <li key={i}><a href={link.anchor}>{link.name}</a></li>;
      }
      )
      }
    </ul>;
  }
}
