import React from 'react';

import InlineForm from '../../components/InlineForm';
import StyleGuideComponentTitle from '../../components/StyleGuideComponentTitle';
import DropdownMenu from '../../components/DropdownMenu';
import Button from '../../components/Button';

export default class StyleGuideLayout extends React.Component {
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
        link: '#layout'
      },
      {
        title: 'Send feedback',
        link: '#layout'
      },
      {
        title: 'Whats New?*',
        link: '#layout'
      },
      {
        title: 'Switch User',
        link: '#layout'
      },
      {
        title: 'Sign out',
        link: '#layout'
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
        title="Layout"
        id="layout"
        link="StyleGuideLayout.jsx"
      />

      <h3> Actions </h3>

      <p>
        For most task-based pages, Primary and Secondary Actions sit under the App Canvas.
        The number of actions per page should be limited intentionally.
        These tasks should relate specifically to the user’s goal for the page they are on.
      </p>

      <p>
        The actions at the bottom of the page are arranged such as the primary task (the task that takes the user forward) is on the bottom right of the App Canvas.
        The label of this action usually hints at the title of the next page.
        Escape actions are placed to the left of the primary action.
        On the bottom left, of the App Canvas, there will be a back link, preferably with a description of where the user will go to or a link to the main page after a user has completed a task.
        These are actions that allow the user to move back a step or completely leave the task they’re working on.
      </p>

      <p>
        The consistent layout and arrangement of these actions reinforces the users mental model as the use Caseflow.
        You should avoid placing these actions in other parts of the page without good reason.
      </p>

      <div className="cf-app cf-push-row cf-sg-layout cf-app-segment cf-app-segment--alt">
          <a href="#" id="cf-logo-link">
            <h1 className="cf-logo"><span className="cf-logo-image cf-logo-image-dispatch">
            </span>Caseflow</h1>
          </a>
          <h2 id="page-title" className="cf-application-title">&nbsp; &nbsp; {name}</h2>

           <div className="cf-dropdown cf-nav-dropdown">
            <DropdownMenu
              options={this.options()}
              onClick={this.handleMenuClick}
              onBlur={this.handleMenuClick}
              label="Establish Claim(DSUSER)"
              menu={this.state.menu}
              />
           </div>
      </div>
      <p>
        <div className="cf-app-segment" id="establish-claim-buttons">
          <div className="usa-width-one-half">
           <InlineForm>
            <span><Button
               name="Back to Preview"
               classNames={['cf-btn-link']} />
            </span>
          </InlineForm>
         </div>

         <div className ="cf-push-right">
           <Button
            name="Cancel"
           classNames={['cf-btn-link']}/>
          <Button
            name="Submit End Product"
          />
         </div>
        </div>
      </p>

    </div>;
  }
  }
