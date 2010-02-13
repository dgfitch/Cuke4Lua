Feature: Pending Steps

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
  
  Scenario: Pending step gives pending output
    Given Cuke4Lua started with a step definition module containing:
      """
      cuke.AllWired = {
        Pending = true,
        Given = "^we're all wired$",
        Step = function()
        end
      }
      """
    When I run cucumber -f pretty -q
    Then it should pass with
      """


        Scenario: Wired
          Given we're all wired
            TODO (Cucumber::Pending)
            features/wired.feature:2:in `Given we're all wired'

      1 scenario (1 pending)
      1 step (1 pending)

      """
