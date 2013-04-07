Feature: Allow a user to create a new reminder

Scenario: Add a new reminder (Declarative)
  # Given I am logged in as TestUser
  When I have added a reminder with title 'Test', start datetime '04/04/2013 12:00', and end datetime '04/04/2013 2:00'
  And I am on the Reminders home page
  Then I should should see a reminder with the title 'Test' on the calendar