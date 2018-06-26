import React from 'react';
import PropTypes from 'prop-types';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import { css } from 'glamor';

const dropdownListStyles = css({
  top: '3rem',
  left: '0',
  width: '12.4em'
});
const dropdownBtnStyles = css({
  marginRight: '2rem'
});

export default class DropdownButton extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      menu: false
    };
  }

  onClick = (title) => {}

  onMenuClick = () => {
    this.setState((prevState) => ({
      menu: !prevState.menu
    }));
  };

  render() {
    const {
      label,
      lists
    } = this.props;

    const dropdownButtonList = () => {
      return <ul className="cf-dropdown-menu active" {...dropdownListStyles}>
        {lists.map((list, index) =>
          <li key={index}>
            <Link className="usa-button-outline usa-button"
              href={list.target}
              onClick={this.onClick(list.title)}>{list.title}</Link>
          </li>)}
      </ul>;
    };

    return <div className="cf-dropdown" {...dropdownBtnStyles}>
      <a href="#dropdown-menu"
        className="cf-dropdown-trigger usa-button usa-button-outline"
        onClick={this.onMenuClick}>
        {label}
      </a>
      {this.state.menu && dropdownButtonList() }

    </div>;
  }
}

DropdownButton.propTypes = {
  list: PropTypes.arrayOf(PropTypes.shape({
    title: PropTypes.string.isRequired,
    link: PropTypes.string.isRequired,
    target: PropTypes.string
  })),
  label: PropTypes.string.isRequired
};
