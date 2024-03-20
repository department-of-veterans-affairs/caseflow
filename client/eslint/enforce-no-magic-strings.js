// enforce-no-magic-strings.js

module.exports = {
  meta: {
    type: 'problem',
    docs: {
      description: 'Enforce that magic strings are stored in COPY.json or client/constants folder.'
    },
    schema: []
  },
  create(context) {
    return {

      // Performs action in the function on every variable declarator
      VariableDeclarator(node) {

        // Check if a `const` variable declaration
        if (node.parent.kind === 'const') {

          // Check if variable name is `foo`
          if (node.id.type === 'Identifier') {

            // Check if value of variable is "bar"
            if (node.init && node.init.type === 'Literal') {

              /*
              * Report error to ESLint.
              */
              context.report({
                node,
                message: 'Magic String usage detected. Please move the value to COPY.json of client/constants folder and then import.',
                data: {
                  notBar: node.init.value
                },
                fix(fixer) {
                  return fixer.replaceText(node.init, '"bar"');
                }
              });
            }
          }
        }
      }
    };
  }
};
