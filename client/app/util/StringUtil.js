import _ from 'lodash';
import React from 'react';
import DOMPurify from 'dompurify';

const StringUtil = {
  camelCaseToDashCase(variable) {
    // convert key from camelCase to dash-case
    return variable.replace(/([A-Z])/g, ($1) => `-${$1.toLowerCase()}`);
  },

  camelCaseToSnakeCase(variable) {
    // convert key from camelCase to snake_case
    if (!variable) {
      return variable;
    }

    return variable.replace(/([A-Z])/g, ($1) => `_${$1.toLowerCase()}`);
  },

  // Converts regular language to camelCase
  // 'VACOLS - 123, User' becomes 'vacolsUser'
  convertToCamelCase(phrase = '') {
    // Code courtesy of Stack Overflow, Question 2970525
    return phrase.
      toLowerCase().
      replace(/[^a-zA-Z ]/g, '').
      replace(/(?:^\w|[A-Z]|\b\w|\s+)/g, (match, index) => {
        if (Number(match) === 0) {
          return '';
        }

        return index === 0 ? match.toLowerCase() : match.toUpperCase();
      });
  },

  capitalizeFirst(str) {
    return str.charAt(0).toUpperCase() + str.slice(1);
  },

  leftPad(string, width, padding = '0') {
    let padded = '';

    for (let i = 0; i < width; i++) {
      padded += padding;
    }

    return (padded + string).slice(-width);
  },

  titleCase(string) {
    return _(string).
      words().
      map(_.capitalize).
      join(' ');
  },

  // https://coderwall.com/p/iprsng/convert-snake-case-to-camelcase
  snakeCaseToCamelCase(variable = '') {
    // convert key from camelCase to snake_case
    return variable?.replace(/(_\w)/g, (found) => found[1].toUpperCase()) ?? '';
  },

  // convert snake_case to Capitalized Words
  snakeCaseToCapitalized(variable = '') {
    return (
      variable
        ?.replace(/_/g, ' ')
        .split(' ')
        .map((word) => {
          return word[0].toUpperCase() + word.substr(1);
        })
        .join(' ') ?? ''
    );
  },

  // convert snake_case to a sentence with the first letter capitalized
  snakeCaseToSentence(variable) {
    const sentence = variable.replace(/_/g, ' ');

    return sentence[0].toUpperCase() + sentence.substring(1);
  },

  html5CompliantId(str) {
    return str.replace(/[^A-Za-z0-9-]/g, '-').replace(/-+/g, '-');
  },

  // convert (Capitalized) Words to lowercase, snake_case, remove punctuation
  parameterize(str) {
    return str.toLowerCase().replace(/\W+/g, '_');
  },

  parseLinks(str = '', { target = '_blank' } = {}) {
    // From https://gist.github.com/dperini/729294
    // eslint-disable-next-line
    const regex = /((?:(?:(?:https?|ftp):)?\/\/)(?:\S+(?::\S*)?@)?(?:(?!(?:10|127)(?:\.\d{1,3}){3})(?!(?:169\.254|192\.168)(?:\.\d{1,3}){2})(?!172\.(?:1[6-9]|2\d|3[0-1])(?:\.\d{1,3}){2})(?:[1-9]\d?|1\d\d|2[01]\d|22[0-3])(?:\.(?:1?\d{1,2}|2[0-4]\d|25[0-5])){2}(?:\.(?:[1-9]\d?|1\d\d|2[0-4]\d|25[0-4]))|(?:(?:[a-z0-9\u00a1-\uffff][a-z0-9\u00a1-\uffff_-]{0,62})?[a-z0-9\u00a1-\uffff]\.)+(?:[a-z\u00a1-\uffff]{2,}\.?))(?::\d{2,5})?(?:[/?#]\S*)?)/gi;

    return DOMPurify.sanitize(
      str.replace(
        regex,
        `<a href="$&" ${target ? `target="${target}"` : ''}>$&</a>`
      )
    );
  },

  // Replace newline ("\n") characters with React-friendly <br /> elements
  nl2br(str) {
    if (typeof str !== 'string') {
      return str;
    }

    const arr = str.split(/\r\n|\r|\n/g);

    return arr.map((txt, idx) => {
      return (
        <React.Fragment key={idx}>
          {txt}
          {idx < arr.length - 1 ? <br /> : null}
        </React.Fragment>
      );
    });
  },
};

export default StringUtil;
