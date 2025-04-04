module.exports = {
  env: {
    es6: true,
    node: true,
  },
  parserOptions: {
    "ecmaVersion": 2018,
  },
  extends: [
    "eslint:recommended",
    "google",
  ],
  rules: {
    "no-restricted-globals": ["error", "name", "length"],
    "prefer-arrow-callback": "error",
    "quotes": ["error", "double", { "allowTemplateLiterals": true }],
    // *** Explicitly set 2-space indent ***
    "indent": ["error", 2], // Explicitly match Google Style Guide
    // *** Fix object spacing and adjust max-len ***
    // Ensure spaces inside the braces for the options object
    "object-curly-spacing": ["error", "always"],
    "max-len": ["warn", { "code": 100, "ignoreUrls": true }], // Warn at 100 chars
    "require-jsdoc": "off", // Disable JSDoc requirement if preferred
    "valid-jsdoc": "off", // Disable JSDoc validation if preferred
  },
  overrides: [
    {
      files: ["**/*.spec.*"],
      env: {
        mocha: true,
      },
      rules: {},
    },
  ],
  globals: {},
};
