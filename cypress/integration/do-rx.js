describe('CI of Rx App', () => {
  it('Visits Replpad', () => {
    cy.visit('http://hostilefork.com/media/shared/replpad-js/')
    cy.get('.input').type('import @rx{enter}')
    cy.get('.stdout')
    cy.contains('Enter your name as appears on a prescription:').type('Graham Chiu')
  })
}) 

