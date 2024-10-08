import React from 'react';
import PropTypes from 'prop-types';
import { GithubIcon } from './icons/fontAwesome/GithubIcon';

export default class StyleGuideComponentTitle extends React.PureComponent {
  render() {
    const {
      id,
      isExternalLink,
      link,
      isSubsection,
      title
    } = this.props;

    let baseUrl;

    const getBaseUrl = () => {
      /* eslint-disable max-len */
      if (isExternalLink) {
        // isExternalLink is for any code sample that's outside the StyleGuide container directory
        baseUrl = 'https://github.com/department-of-veterans-affairs/caseflow';
      } else {
        baseUrl = 'https://github.com/department-of-veterans-affairs/caseflow/blob/main/client/app/containers/StyleGuide/';
      }
      /* eslint-enable max-len */

      return baseUrl;
    };

    const ViewSourceCodeLink = (props) => {

      return <span>
        <a
          className="usa-button"
          href={getBaseUrl() + props.link}
          target="_blank"
          rel="noopener noreferrer"
        >
          <GithubIcon /> View source code
        </a>
      </span>;
    };

    /* Link is only the name of the file that you want to link to in the
    Style Guide (aka StyleGuideModal.jsx). If you use isExternalLink===true
    then you will use the full path after the caseflow repo.*/
    return <div className="cf-sg-section-source">
      <div className="cf-push-left">
        {!isSubsection && <h2 id={id}>{title}</h2>}
        {isSubsection && <h3 id={id} className="cf-sg-subsection">{title}</h3>}
      </div>

      {link && <div className="cf-push-right">
        <ViewSourceCodeLink link={link} />
      </div>}
    </div>;
  }
}

StyleGuideComponentTitle.propTypes = {
  id: PropTypes.string.isRequired,
  isExternalLink: PropTypes.bool,
  isSubsection: PropTypes.bool,
  link: PropTypes.string,
  title: PropTypes.string.isRequired
};
