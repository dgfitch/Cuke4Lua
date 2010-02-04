Feature: Run Cuke4Lua and Cucumber from a single command

  Background:
    Given a standard Cucumber project directory structure
    And a file named "features/wired.feature" with:
      """
        Scenario: Wired
          Given we're all wired

      """
    And a file named "features/step_definitions/some_remote_place.wire" with:
      """
      host: localhost
      port: 3901

      """
      
    Scenario: A passing step
      Given a step definition module containing:
        """
        { AllWired = {
          Given = "^we're all wired$"
          Step = function()
          end
        }
        """
      When I run the cuke4lua wrapper
      Then STDERR should be empty
      And it should pass with
        """
        .

        1 scenario (1 passed)
        1 step (1 passed)

        """
        
    Scenario: A failing step
      Given a step definition module containing:
        """
        { AllWired = {
          Given = "^we're all wired$"
          Step = function()
            error "message"
          end
        }
        """
      When I run the cuke4lua wrapper
      Then it should fail
