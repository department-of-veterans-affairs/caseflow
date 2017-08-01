import React from 'react';
import StyleGuideComponentTitle from '../../components/StyleGuideComponentTitle';
import Button from '../../components/Button';
import DropdownMenu from '../../components/DropdownMenu';

export default class StyleGuideFooter extends React.Component {
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
        title: 'Help',
        link: '#footer'
      },
      {
        title: 'Send feedback',
        link: '#footer'
      },
      {
        title: 'Switch User',
        link: '#footer'
      },
      {
        title: 'Sign out',
        link: '#footer'
      }
    ];
  }


  render() {
    let {
      name
    } = this.props;

    name = 'Dispatch';

    return <div>
      <StyleGuideComponentTitle
        title="Footer"
        id="footer"
        link="StyleGuideFooter.jsx"
        isSubsection={true}
    />
    <p>
     All of Caseflow Apps feature a minimal footer that contains the text
    “Built with ♡ by the Digital Service at the VA.” and a “Send Feedback” link.</p>

    <p>
     Conveniently, if a developer hover’s over the word
     “Built” they’ll see a tooltip showing the build date
     of the app that they are viewing.</p>


   <div>
      <nav className="cf-nav">
        <a href="#" id="cf-logo-link">
          <h1 className="cf-logo"><span className="cf-logo-image cf-logo-image-dispatch">
          </span>Caseflow</h1>
        </a>
          <h2 id="page-title" className="cf-application-title">&nbsp; &nbsp; {name}</h2>
          <div className="cf-dropdown cf-nav-dropdown">
            <DropdownMenu
              options={this.options()}
              onClick={this.handleMenuClick}
              onBlur={this.handleMenuCliJck}
              label="KAVI HARSHAWAT"
              menu={this.state.menu}
              />
          </div>
      </nav>
    </div>

    <div className="cf-app-segment cf-app-segment--alt"></div>
    <div className="cf-app-segment" id="establish-claim-buttons">
      <div className="cf-push-left">
        <Button
          name="View Work History"
          classNames={['cf-btn-link']}
        />
      </div>
      <div className="cf-push-right">
        <span className="cf-button-associated-text-right">
         30 cases assigned, 5 completed
         </span>
        <Button
          name="Establish Next Claim"
          classNames={['usa-button-primary']}
        />
      </div>
    </div>

    <div className="cf-sg-footer">
      <footer className="cf-txt-c cf-app-footer">
       <div>
          <div className="cf-push-left">
             <span title="Recent build date goes here">Built </span> with <abbr title="love">♡</abbr> by
            the <a href="https://www.usds.gov/">Digital Service at
            the <abbr title="Department of Veterans Affairs">VA</abbr>
            </a>
          </div>
          <div className="cf-push-right">
            <a href="#">
             Send feedback
            </a>
          </div>
        </div>
      </footer>
    </div>
  </div>;
  }
}
