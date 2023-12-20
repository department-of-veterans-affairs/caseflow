import React from 'react';
import StyleGuideComponentTitle from '../../components/StyleGuideComponentTitle';
import DropdownButton from '../../components/DropdownButton';

export default class StyleGuideDropdownButton extends React.PureComponent {
  render = () => {

    const options = [
      {
        title: 'Styleguide',
        target: '/styleguide' },
      {
        title: 'Help',
        target: '/help' }
    ];

    return <React.Fragment>
      <StyleGuideComponentTitle
        title="Dropdown Button"
        id="dropdown-button"
        link="StyleGuideDropdownButton.jsx"
        isSubsection
      />
      <div className="usa-grid">
        <DropdownButton
          lists={options}
          onClick={this.handleMenuClick}
          label="Dropdown Button"
        />
      </div>
    </React.Fragment>;
  }
}

