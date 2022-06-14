const { defineConfig } = require('cypress')

module.exports = defineConfig({
  projectId: "zpvrpm",  // humanistic @ cypress.io
  defaultCommandTimeout: 15000,

  e2e: {
    specPattern: 'e2e/**/*.cy.{js,jsx,ts,tsx}',
    supportFile: 'support/e2e.{js,jsx,ts,tsx}',

    setupNodeEvents(on, config) {
      // implement node event listeners here
    },
  },
})
