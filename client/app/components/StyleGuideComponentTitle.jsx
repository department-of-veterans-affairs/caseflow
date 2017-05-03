import React, { PropTypes } from 'react';
import { GithubIcon } from './RenderFunctions';

export default class StyleGuideComponentTitle extends React.Component {
  render() {
    let {
      id,
      link,
      isSubsection,
      title
    } = this.props;

    let ViewSourceCodeLink = (props) => {

      /* eslint-disable max-len */
      let baseUrl = 'https://github.com/department-of-veterans-affairs/caseflow/blob/master/client/app/containers/StyleGuide/';

      /* eslint-enable max-len */

      return <span>
        <a className="usa-button" href={baseUrl + props.link} target="_blank">
          <GithubIcon /> View source code
        </a>
      </span>;
    };

    /* Link is only the name of the file that you want to link to in the
    Style Guide (aka StyleGuideModal.jsx)*/
    return <div className="cf-sg-section-source">
      <div className="cf-push-left">
        {!isSubsection && <h2 id={id}>{title}</h2>}
        {isSubsection && <h3 id={id} className="cf-sg-subsection">{title}</h3>}
      </div>

      <div className="cf-push-right">
        <ViewSourceCodeLink link={link} />
      </div>
    </div>;
  }
}

StyleGuideComponentTitle.props = {
  id: PropTypes.string.isRequired,
  isSubsection: PropTypes.bool,
  link: PropTypes.string.isRequired,
  title: PropTypes.string.isRequired
};
