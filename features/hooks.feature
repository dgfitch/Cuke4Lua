Feature: Run Lua Before and After hooks from Cucumber

  Background:
    Given a standard Cucumber project directory structure
    And a file named "features/step_definitions/some_remote_place.wire" with:
      """
      host: localhost
      port: 3901

      """
    
  Scenario: Before hook
    Given a file named "features/adding.feature" with:
      """
        Scenario: Cuke count set in Before
          Then I should have 4 cukes

      """
    And Cuke4Lua started with a step definition module containing:
      """
      count = 0

      cuke.Setup = {
        Before = true,
        Step = function()
          count = 4
        end
      }

      cuke.ExpectCukes = {
        Given = "^I should have (\d+) cukes$",
        Step = function(cukes)
          assert(count == cukes, string.format("Expected %s, got %s cukes", cukes, count))
        end
      }
      """
    When I run cucumber -f progress features
    Then STDERR should be empty
    And it should pass with
      """
      .

      1 scenario (1 passed)
      1 step (1 passed)

      """
      
  Scenario: After hook throws exception (how else do we know it's called?)
    Given a file named "features/adding.feature" with:
      """
        Scenario: After hook defined
          Given a passing step

      """
    And Cuke4Lua started with a step definition module containing:
      """
      cuke.Teardown = {
        After = true,
        Step = function()
          error "EXPLODE!"
        end
      }

      cuke.PassingStep = {
        Then = "^a passing step$",
        Step = function()
        end
      }
      """
    When I run cucumber -f progress features
    Then it should fail
